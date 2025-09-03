for FILE in src/*.sv; do
  /home/animated/Downloads/sv2v-Linux/sv2v $FILE >> src_v/${FILE:4:-3}.v
done
