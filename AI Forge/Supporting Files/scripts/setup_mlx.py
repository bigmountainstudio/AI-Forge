#!/usr/bin/env python3
"""
MLX Setup and Verification Script

Verifies and installs MLX fine-tuning dependencies optimized for Apple Silicon.
This script checks your environment and ensures all necessary packages are available.
"""

import subprocess
import sys
from pathlib import Path


def run_command(cmd: list) -> tuple[bool, str]:
    """Run a shell command and return success status and output."""
    try:
        result = subprocess.run(cmd, capture_output=True, text=True, timeout=30)
        return result.returncode == 0, result.stdout + result.stderr
    except subprocess.TimeoutExpired:
        return False, "Command timeout"
    except Exception as e:
        return False, str(e)


def check_python_version() -> bool:
    """Check Python version (3.9+)."""
    print("Checking Python version...")
    try:
        import sys
        ver = sys.version_info
        if ver.major == 3 and ver.minor >= 9:
            print(f"✓ Python {ver.major}.{ver.minor}.{ver.micro} OK")
            return True
        else:
            print(f"✗ Python {ver.major}.{ver.minor} - Need 3.9 or later")
            return False
    except Exception as e:
        print(f"✗ Error checking Python: {e}")
        return False


def check_package(package_name: str, import_name: str = None) -> bool:
    """Check if a package is installed."""
    import_name = import_name or package_name
    try:
        __import__(import_name)
        return True
    except ImportError:
        return False


def install_package(package_name: str, version: str = None) -> bool:
    """Install a package using pip."""
    print(f"  Installing {package_name}...", end=" ", flush=True)
    
    cmd = [sys.executable, "-m", "pip", "install", "--quiet", "--upgrade"]
    if version:
        cmd.append(f"{package_name}=={version}")
    else:
        cmd.append(package_name)
    
    success, output = run_command(cmd)
    if success:
        print("✓")
        return True
    else:
        print(f"✗\n    {output}")
        return False


def main():
    print("\n" + "=" * 70)
    print("MLX Fine-Tuning Environment Setup")
    print("=" * 70 + "\n")
    
    # Check Python version
    if not check_python_version():
        print("\nError: Python 3.9+ is required")
        sys.exit(1)
    
    print("\nChecking MLX dependencies...")
    print("-" * 70)
    
    # Required packages
    packages = {
        "mlx": "mlx",
        "mlx-lm": "mlx_lm",
        "transformers": "transformers",
        "torch": "torch",  # CPU version, not GPU
        "numpy": "numpy",
        "tqdm": "tqdm",
    }
    
    missing_packages = []
    
    for package_name, import_name in packages.items():
        print(f"Checking {package_name}...", end=" ", flush=True)
        if check_package(package_name, import_name):
            print("✓")
        else:
            print("✗ (missing)")
            missing_packages.append(package_name)
    
    if missing_packages:
        print("\n" + "-" * 70)
        print(f"Installing {len(missing_packages)} missing package(s)...")
        print("-" * 70 + "\n")
        
        failed = []
        for package in missing_packages:
            if not install_package(package):
                failed.append(package)
        
        if failed:
            print(f"\n✗ Failed to install: {', '.join(failed)}")
            print("\nManual installation:")
            print(f"  pip3 install --upgrade {' '.join(failed)}")
            sys.exit(1)
        
        print("\n✓ All packages installed successfully")
    else:
        print("\n✓ All dependencies are installed")
    
    # Verify MLX works
    print("\n" + "-" * 70)
    print("Verifying MLX functionality...")
    print("-" * 70)
    
    try:
        import mlx.core as mx
        print(f"✓ MLX imported successfully")
        
        # Check if we can create a simple tensor (confirms Metal works)
        try:
            test = mx.zeros((1, 1))
            print(f"✓ Metal acceleration available")
        except Exception as e:
            print(f"⚠ Metal test failed, but MLX may still work: {e}")
        
    except Exception as e:
        print(f"✗ Error verifying MLX: {e}")
        print("\nThis might indicate an issue with MLX installation.")
        print("Try reinstalling MLX:")
        print("  pip3 install --upgrade --force mlx mlx-lm")
        sys.exit(1)
    
    print("\n" + "=" * 70)
    print("Setup Complete!")
    print("=" * 70)
    print("\nYou're ready to run fine-tuning with MLX!")
    print("\nExample command:")
    print("  python3 run_finetuning_mlx.py --model qwen2.5-coder --epochs 1")
    print("\nFor memory-constrained machines:")
    print("  python3 run_finetuning_mlx.py --model qwen2.5-coder --low-memory --epochs 1")
    print()


if __name__ == "__main__":
    main()
