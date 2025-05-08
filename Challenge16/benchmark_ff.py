import torch, time, csv, argparse

class SimpleNet(torch.nn.Module):
    def __init__(self, layer_sizes):
        super().__init__()
        layers, in_size = [], 4
        for out_size in layer_sizes:
            layers += [torch.nn.Linear(in_size, out_size), torch.nn.ReLU()]
            in_size = out_size
        layers.append(torch.nn.Linear(in_size, 1))
        self.net = torch.nn.Sequential(*layers)

    def forward(self, x):
        return self.net(x)

def bench(layer_sizes, device, batch, steps):
    model = SimpleNet(layer_sizes).to(device)
    x = torch.randn(batch, 4, device=device)
    for _ in range(10):
        _ = model(x)
    if device.type=='cuda': torch.cuda.synchronize()
    t0 = time.time()
    for _ in range(steps):
        _ = model(x)
    if device.type=='cuda': torch.cuda.synchronize()
    return (time.time()-t0)*1000

if __name__=="__main__":
    p = argparse.ArgumentParser()
    p.add_argument("--layers", nargs="+", type=int, default=[5])
    p.add_argument("--batch", type=int, default=128)
    p.add_argument("--steps", type=int, default=1000)
    args = p.parse_args()

    # CSV header (once)
    if not [f for f in ["pytorch_times.csv"] if True]:
        pass

    cpu = bench(args.layers, torch.device("cpu"), args.batch, args.steps)
    gpu = bench(args.layers, torch.device("cuda"), args.batch, args.steps) \
          if torch.cuda.is_available() else -1

    with open("pytorch_times.csv","a",newline="") as f:
        w = csv.writer(f)
        arch = "IN4_" + "_".join(map(str,args.layers)) + "_O1"
        w.writerow([arch, f"{cpu:.3f}", f"{gpu:.3f}"])
    print(f"{arch}: CPU {cpu:.3f} ms, GPU {gpu:.3f} ms")
