"""Train and quantize a small MNIST model for the Tensor Core.

Trained with power-of-2 quantization scales so arithmetic reduces to bit shifts.
Outputs: quantized_tensor_core_mnist.pt (state dict with packed quantized weights).
"""
import torch
import torch.nn as nn
import torch.nn.functional as F
import torch.optim as optim
from torchvision import datasets, transforms
from torch.optim.lr_scheduler import StepLR
import math

torch.manual_seed(42)
device = torch.device('cuda' if torch.cuda.is_available() else 'cpu')
torch.backends.quantized.engine = 'qnnpack'


class Net(nn.Module):
    def __init__(self, hidden=128):
        super().__init__()
        self.quant = torch.quantization.QuantStub()
        self.fc1 = nn.Linear(784, hidden, bias=False)
        self.relu1 = nn.ReLU()
        self.fc2 = nn.Linear(hidden, 10, bias=False)
        self.dequant = torch.quantization.DeQuantStub()

    def forward(self, x):
        x = self.quant(torch.flatten(x, 1))
        x = self.relu1(self.fc1(x))
        x = self.dequant(self.fc2(x))
        return F.sigmoid(x)


class PowerOfTwoObserver(torch.quantization.MinMaxObserver):
    """Quantization observer that constrains scales to powers of two."""

    def calculate_qparams(self):
        min_val, max_val = self.min_val.item(), self.max_val.item()
        max_range = max(abs(min_val), abs(max_val))
        scale = 2 ** math.ceil(math.log2(max_range / (self.quant_max - self.quant_min)))

        if self.qscheme == torch.per_tensor_symmetric and self.dtype == torch.qint8:
            zero_point = 0
        elif self.qscheme == torch.per_tensor_symmetric:
            zero_point = 128
        else:
            zero_point = self.quant_min - round(min_val / scale)

        return torch.tensor(scale, dtype=torch.float32), torch.tensor(zero_point, dtype=torch.int64)


def train_epoch(model, device, loader, optimizer):
    model.train()
    for batch_idx, (data, target) in enumerate(loader):
        data, target = data.to(device), target.to(device)
        optimizer.zero_grad()
        loss = F.binary_cross_entropy(model(data), F.one_hot(target, 10).float())
        loss.backward()
        optimizer.step()
        if batch_idx % 100 == 0:
            print(f"  [{batch_idx * len(data)}/{len(loader.dataset)}] Loss: {loss.item():.4f}")


def evaluate(model, device, loader, label="Test"):
    model.eval()
    correct = 0
    with torch.no_grad():
        for data, target in loader:
            data, target = data.to(device), target.to(device)
            pred = model(data).argmax(dim=1)
            correct += pred.eq(target).sum().item()
    acc = 100. * correct / len(loader.dataset)
    print(f"{label}: {correct}/{len(loader.dataset)} ({acc:.1f}%)")
    return acc


def compute_quantized(input_float, q_model):
    """Reference forward pass using quantized integer arithmetic (no framework quantization).

    Simulates the exact computation the hardware performs: integer matmul → bit-shift scaling → ReLU clamp.
    """
    input_scale = q_model.quant.scale.item() if hasattr(q_model, 'quant') else 1.0
    input_log2 = int(math.log2(input_scale))
    x = torch.clamp(torch.round(input_float * (2 ** -input_log2)).int(), -16, 15)

    for name, module in q_model.named_modules():
        if not isinstance(module, (torch.nn.quantized.Linear, torch.nn.intrinsic.quantized.LinearReLU)):
            continue
        w_int = module.weight().int_repr().int()
        total_shift = (input_log2 + int(math.log2(module.weight().q_scale()))) - int(math.log2(module.scale))
        acc = F.linear(x.float(), w_int.float()).long()
        out = acc >> (-total_shift) if total_shift < 0 else acc << total_shift

        if isinstance(module, torch.nn.intrinsic.quantized.LinearReLU):
            x = torch.clamp(out, 0, 15).int()
        else:
            x = torch.clamp(out, -16, 15).int()
        input_log2 = int(math.log2(module.scale))

    return torch.sigmoid(x * (2.0 ** input_log2))


if __name__ == "__main__":
    transform = transforms.Compose([transforms.ToTensor(), lambda y: y.to(torch.float)])
    train_set = datasets.MNIST('../data', train=True, download=True, transform=transform)
    test_set = datasets.MNIST('../data', train=False, transform=transform)

    loader_kwargs = {'num_workers': 1, 'persistent_workers': True, 'pin_memory': True, 'shuffle': True}
    train_loader = torch.utils.data.DataLoader(train_set, batch_size=32, **loader_kwargs)
    test_loader = torch.utils.data.DataLoader(test_set, batch_size=32, **loader_kwargs)

    # Train
    model = Net().to(device)
    optimizer = optim.Adadelta(model.parameters(), lr=10)
    scheduler = StepLR(optimizer, step_size=1, gamma=0.7)

    for epoch in range(10):
        print(f"Epoch {epoch}")
        train_epoch(model, device, train_loader, optimizer)
        evaluate(model, device, test_loader)
        scheduler.step()

    torch.save(model.state_dict(), "non_quantized_tensor_core_mnist.pt")

    # Quantize
    model = Net()
    model.load_state_dict(torch.load("non_quantized_tensor_core_mnist.pt"))
    model.cpu().eval()

    torch.quantization.fuse_modules(model, [['fc1', 'relu1']], inplace=True)
    model.qconfig = torch.quantization.QConfig(
        activation=PowerOfTwoObserver.with_args(dtype=torch.qint8, quant_min=-16, quant_max=15, qscheme=torch.per_tensor_symmetric),
        weight=PowerOfTwoObserver.with_args(dtype=torch.qint8, quant_min=-16, quant_max=15, qscheme=torch.per_tensor_symmetric),
    )
    torch.quantization.prepare(model, inplace=True)

    with torch.no_grad():
        for images, _ in train_loader:
            model(images)

    quantized_model = torch.quantization.convert(model, inplace=False)

    print(f"\nInput scale: {quantized_model.quant.scale.item()}")
    for name, module in quantized_model.named_modules():
        if isinstance(module, (torch.nn.intrinsic.quantized.LinearReLU, torch.nn.quantized.Linear)):
            print(f"  {name}: scale={module.scale}, log2={math.log2(module.scale):.0f}")

    evaluate(quantized_model, device, test_loader, "Quantized")
    torch.save(quantized_model.state_dict(), "quantized_tensor_core_mnist.pt")