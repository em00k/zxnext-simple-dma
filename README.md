# zxnext-simple-dma
Simple DMA playback on the ZX Next

Here is a quick example of using the DMA for sample sound effects.

Each sample can be up to 8k in size, and store in ram banks, $e000 is reserved for the samples but could be moved.

Each sample is 5512Hz saved RAW and also supports looping. You can probably make a lot of improvements, but this is 100% more dma sample playback code than before I wrote it 
