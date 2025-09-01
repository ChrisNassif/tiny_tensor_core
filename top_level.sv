module top_level ();
    reg [8*45:0] machine_code;
	integer file_descriptor;

	initial begin
	  file_descriptor = $fopen("my_file.txt", "r");

	  // Keep reading lines until EOF is found
      while (! $feof(file_descriptor)) begin

      	// Get current line into the variable 'str'
        $fgets(machine_code, file_descriptor);

        // Display contents of the variable
        $display("%0s", machine_code);
      end
      $fclose(file_descriptor);
	end


endmodule