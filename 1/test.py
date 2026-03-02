import math

with open("hello.asm", "r") as file:
    lines = [i.strip() for i in file if i.split(" ")[0] in ["a", "b", "c", "d", "e"]]

# print(lines)
dict = {}
for i in lines:
    dict[i.split(" ")[0]] = int(i.split(" ")[2])
# print(dict)


delimoe = (dict["d"] + dict["b"]) * (dict["a"] - dict["c"]) + (
    dict["e"] - dict["b"]
) * (dict["e"] + dict["b"])
print(int(abs(delimoe) // (dict["b"] ** 2) * math.copysign(1, delimoe)))
