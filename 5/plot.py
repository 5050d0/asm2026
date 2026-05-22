#!/usr/bin/env python3
import json
import os
import matplotlib.pyplot as plt

RESULTS_FILE = "benchmark_results.json"

def main():
    if not os.path.exists(RESULTS_FILE):
        print(f"Ошибка: Файл {RESULTS_FILE} не найден.")
        return

    with open(RESULTS_FILE, "r", encoding="utf-8") as f:
        data = json.load(f)

    if not data:
        print("Нет данных для отображения.")
        return

    # Группируем данные по картинкам
    images_info = {}
    for entry in data:
        img = entry["image"]
        opt = entry["optimization"]
        pixels = entry["pixels"]
        
        if img not in images_info:
            images_info[img] = {
                "pixels": pixels,
                "asm_times": [],
                "c_times": {}
            }
            
        images_info[img]["c_times"][opt] = entry["c_time"]
        images_info[img]["asm_times"].append(entry["asm_time"])

    # Превращаем в список и сортируем по количеству пикселей (для правильной оси X)
    sorted_images = sorted(images_info.values(), key=lambda x: x["pixels"])

    # Подготавливаем списки осей
    # Переведем пиксели в мегапиксели для красоты шкалы (опционально)
    x_pixels = [img["pixels"] for img in sorted_images]
    
    # Усредняем время asm (так как оно не зависит от флагов С)
    y_asm = [sum(img["asm_times"])/len(img["asm_times"]) for img in sorted_images]
    
    opt_levels = ["O0", "O1", "O2", "O3", "Ofast"]
    y_c_opts = {opt: [] for opt in opt_levels}
    
    for img in sorted_images:
        for opt in opt_levels:
            # Если по какой-то причине данных нет, ставим None
            y_c_opts[opt].append(img["c_times"].get(opt, None))

    # --- Отрисовка ---
    plt.figure(figsize=(10, 6))

    # Линия ассемблера (красная, толстая, чтобы выделялась)
    plt.plot(x_pixels, y_asm, marker='o', color='red', linewidth=2.5, label='ASM')

    # Линии для каждого уровня оптимизации C (сине-зеленая гамма)
    colors = ['#b3cde0', '#6497b1', '#005b96', '#03396c', '#011f4b']
    for opt, color in zip(opt_levels, colors):
        plt.plot(x_pixels, y_c_opts[opt], marker='s', color=color, linewidth=1.5, label=f'C (-{opt})')

    plt.title('Сравнение производительности: ASM против C (разные уровни оптимизации)')
    plt.xlabel('Размер изображения (количество пикселей)')
    plt.ylabel('Время выполнения (секунды)')
    
    plt.grid(True, linestyle='--', alpha=0.7)
    plt.legend()
    
    # Форматируем ось X, чтобы числа не сливались в кашу (например: 1,000,000 вместо 1e6)
    plt.gca().get_xaxis().set_major_formatter(
        plt.matplotlib.ticker.FuncFormatter(lambda x, p: format(int(x), ','))
    )

    plt.tight_layout()
    plt.savefig("benchmark_plot_line.png")
    print("График сохранен как 'benchmark_plot_line.png'")
    plt.show()

if __name__ == "__main__":
    main()
