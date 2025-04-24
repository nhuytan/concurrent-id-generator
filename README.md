# 🧾 Concurrent ID Generator (Bash)

This project provides a concurrency-safe shell script that generates **unique, sequential, zero-padded IDs** in multi-process environments using file locks. It’s ideal for situations where multiple processes need to generate non-conflicting identifiers.

---

## 🚀 Run and Test in Google Colab

Follow these steps to clone, set up, and test the ID generator directly in **Google Colab**.

---

## 🧱 Step 1: Clone the Repository

Start by cloning the GitHub repository into your Colab environment:

```bash
!rm -rf concurrent-id-generator
!git clone https://github.com/nhuytan/concurrent-id-generator.git

```

## 🔧 Step 2: Make Scripts Executable

```bash
!chmod +x concurrent-id-generator/genid.sh concurrent-id-generator/testid.sh
```

## 🧪 Step 3: Run testid.sh

You can run the test script in various modes:

1️. Silent Mode (no console output)

```bash 
!concurrent-id-generator/testid.sh 10
```

2️. Verbose Mode (prints PID → ID)

```bash 
!concurrent-id-generator/testid.sh -v 10
```

3. Default Mode (10 processes if number omitted)

```bash 
!concurrent-id-generator/testid.sh
```

4. Timed Execution (Benchmark performance using the time command):
```bash 
!time concurrent-id-generator/testid.sh -v 10
```


