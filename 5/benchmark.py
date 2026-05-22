#!/usr/bin/env python3
import os
import subprocess
import shutil
import glob
import json
import re

OPTIMIZATIONS = {
    "O0":    ["-Doptimization=0"],
    "O1":    ["-Doptimization=1"],
    "O2":    ["-Doptimization=2"],
    "O3":    ["-Doptimization=3"],
    "Ofast": ["-Doptimization=3", "-Dc_args=-Ofast"]
}

IMAGES_DIR = "images"
RESULTS_FILE = "benchmark_results.json"

def build_project(opt_name, meson_args):
    build_dir = f"build_{opt_name}"
    print(f"\n[{opt_name}] Настройка и сборка проекта...")
    
    if os.path.exists(build_dir):
        shutil.rmtree(build_dir)
        
    subprocess.run(["meson", "setup", build_dir] + meson_args, check=True, stdout=subprocess.DEVNULL)
    subprocess.run(["meson", "compile", "-C", build_dir], check=True, stdout=subprocess.DEVNULL)
    
    return os.path.join(build_dir, "lab5")

def run_benchmark(executable, image_path):
    print(f"  Тестирование: {image_path}")
    cmd = [executable, "-i", image_path, "--bench"]
    
    result = subprocess.run(cmd, capture_output=True, text=True, check=True)
    
    times = {}
    pixels = 0
    
    for line in result.stdout.splitlines():
        # Ищем размер, например: "Size: 1920×1080  bit_depth=8..." (или с 'x' вместо '×')
        m_size = re.search(r"Size:\s*(\d+)[x×](\d+)", line)
        if m_size:
            pixels = int(m_size.group(1)) * int(m_size.group(2))
            
        # Ищем время
        m_time = re.search(r"^\s*(c|asm)\s+([\d\.]+)\s+[sс]", line)
        if m_time:
            times[m_time.group(1)] = float(m_time.group(2))
            
    return times, pixels

def main():
    images = glob.glob(os.path.join(IMAGES_DIR, "*.png"))
    if not images:
        print(f"Ошибка: Не найдено PNG изображений в папке '{IMAGES_DIR}'.")
        return

    results = []

    for opt_name, meson_args in OPTIMIZATIONS.items():
        executable = build_project(opt_name, meson_args)
        
        for img in images:
            img_name = os.path.basename(img)
            times, pixels = run_benchmark(executable, img)
            
            if 'c' in times and 'asm' in times and pixels > 0:
                results.append({
                    "image": img_name,
                    "pixels": pixels,
                    "optimization": opt_name,
                    "c_time": times['c'],
                    "asm_time": times['asm']  # Сохраняем, но при отрисовке возьмем среднее
                })
            else:
                print(f"  [!] Ошибка получения данных (бенчмарка или размера) для {img_name}")

    with open(RESULTS_FILE, "w", encoding="utf-8") as f:
        json.dump(results, f, indent=4)
    
    print(f"\nГотово! Результаты сохранены в {RESULTS_FILE}")

if __name__ == "__main__":
    main()
