# FFmpeg docker build with CUDA accerlation

Build the image:

```sh
docker build -t ffmpeg .
```

Then run the image with GPU-enabled docker:

```sh
docker run --rm -it \
    --gpus --all \
    -e NVIDIA_VISIBLE_DEVICES=all \
    -e NVIDIA_DRIVER_CAPABILITIES=compute,utility,video \
    -v "/path/to/your/video:/workspace"
    ffmpeg \
        -i "input file"
        ...
```
