#!/usr/bin/env python3
"""Check GPU availability and PyTorch CUDA support"""
import sys
import os

# Check for NVIDIA GPU via system
try:
    import subprocess
    result = subprocess.run(['nvidia-smi'], capture_output=True, text=True, timeout=5)
    if result.returncode == 0:
        print("NVIDIA GPU detected via nvidia-smi:")
        print(result.stdout.split('\n')[0:5])
    else:
        print("nvidia-smi not available (this is OK if using NVIDIA Container Runtime)")
except (FileNotFoundError, subprocess.TimeoutExpired):
    print("nvidia-smi not found (expected if using NVIDIA Container Runtime)")

try:
    import torch
    print("=" * 50)
    print("PyTorch CUDA Detection Report")
    print("=" * 50)
    print(f"PyTorch version: {torch.__version__}")
    print(f"PyTorch location: {torch.__file__}")
    
    # Check if it's CPU or CUDA build
    if '+cpu' in torch.__version__:
        print("WARNING: PyTorch CPU version detected!")
    elif '+cu' in torch.__version__:
        print(f"PyTorch CUDA build detected: {torch.__version__.split('+')[1]}")
    
    print(f"CUDA available: {torch.cuda.is_available()}")
    if torch.cuda.is_available():
        print(f"CUDA version: {torch.version.cuda}")
        try:
            print(f"cuDNN version: {torch.backends.cudnn.version()}")
        except:
            print("cuDNN version: N/A")
        print(f"Number of GPUs: {torch.cuda.device_count()}")
        for i in range(torch.cuda.device_count()):
            print(f"  GPU {i}: {torch.cuda.get_device_name(i)}")
            props = torch.cuda.get_device_properties(i)
            print(f"    Memory: {props.total_memory / 1024**3:.2f} GB")
            print(f"    Compute Capability: {props.major}.{props.minor}")
        print("=" * 50)
        print("SUCCESS: GPU is available and PyTorch can use it!")
    else:
        print("=" * 50)
        print("WARNING: CUDA is not available in PyTorch!")
        print("Possible reasons:")
        print("  1. PyTorch CPU version is installed")
        print("  2. CUDA libraries not found (check LD_LIBRARY_PATH)")
        print("  3. GPU drivers not accessible from container")
        print("=" * 50)
        print("LD_LIBRARY_PATH:", os.environ.get('LD_LIBRARY_PATH', 'Not set'))
        print("=" * 50)
        # Don't exit with error, just warn
        sys.exit(0)
except ImportError:
    print("ERROR: PyTorch not installed!")
    sys.exit(1)

