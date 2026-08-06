# 🛰️ UART to Register Map Controller IP Design

> **FPGA (Artix-7 / Cmod A7) 환경에서 12MHz 시스템 클럭을 기반으로 동작하는 고신뢰성 UART IP 및 AXI4-Lite 레지스터 맵 제어기 설계 프로젝트입니다.**

---

## 📌 Project Overview

본 프로젝트는 외부 PC(시리얼 터미널)와의 UART 직렬 통신 패킷을 수신하여 온칩 **AXI4-Lite 버스 트랜잭션으로 변환**하고, 내부 레지스터 맵(Register File)의 데이터를 정밀 읽기/쓰기 제어하는 하드웨어 IP 시스템입니다.

* **Target Board:** Xilinx Cmod A7-35T (Artix-7 XC7A35T-1CPG236C)
* **System Clock:** 12 MHz (T = 83.33ns)
* **Design Language:** Verilog HDL / SystemVerilog
* **EDA Tool:** Xilinx Vivado
* **Core Protocols:** UART (9600 bps, 16x Oversampling) <-> AXI4-Lite Slave Protocol

---

## 🏗️ System Architecture

전체 시스템은 **UART Top**, **UART-to-AXI Bridge**, **AXI4-Lite Slave**의 3가지 핵심 IP 블록이 AMBA AXI4-Lite 표준 버스를 통해 바인딩된 계층 구조로 설계되었습니다.

    +-----------------+      UART      +-------------------+    Internal    +------------------+
    | PC / Terminal   | <------------> | UART Top (RX/TX)  | <------------> | UART-AXI Bridge  |
    +-----------------+   (9600 bps)   +-------------------+  (Pulse/Done)  +------------------+
                                                                                 |
                                                                            AXI4-Lite Bus
                                                                                 |
                                                                        +------------------+
                                                                        | AXI4-Lite Slave  |
                                                                        | (Register File)  |
                                                                        +------------------+

### 🧩 Module Specifications

| 모듈명 | 주요 기능 | 적용된 하드웨어 아키텍처 및 특징 |
| :--- | :--- | :--- |
| **`uart_baud_gen`** | 시스템 클럭 분주 및 샘플링 틱 생성 | 12MHz -> 153.6kHz (분주비 78, 오차율 0.15% 미만), 7-bit Counter |
| **`uart_rx`** | 직렬 데이터를 8-bit 병렬 데이터로 복원 | 16x Oversampling (7th tick 정중앙 타격), Registered Output (`rx_done` 1-clock pulse) |
| **`uart_tx`** | 8-bit 병렬 데이터를 직렬 내보냄 | `IDLE`-`START`-`DATA`-`STOP` 2-Block FSM, 무한 연사 방지 1-clock start pulse 제어 |
| **`uart_axi_bridge`** | UART 패킷 <-> AXI4-Lite 버스 변환 | Command Parser ('W'/'R'), Shift Concatenation (32-bit), Master-driven VALID assertion |
| **`axi_lite_slave`** | AXI4-Lite 응답 및 레지스터 기입 | 4-State Decoupled Write FSM, Zero-Latency Write, 1-Cycle Read Latency, Write Strobe |

---

## 🚀 Key Engineering Highlights

### 1. STA 마진 확보를 위한 2-Block FSM & Zero-Latch Synthesis
* 조합회로(`always_comb`)와 순차회로(`always_ff`)의 역할을 철저히 분리한 **2-Block FSM 아키텍처**를 적용하여 Combinational Cloud 깊이를 최소화했습니다.
* 조합회로 블록 최상단에 **Default Assignment** 테크닉을 일괄 적용하여 미정의 경로에 따른 의도치 않은 **Latch 합성을 100% 차단**했습니다.

### 2. AXI4-Lite Valid-Data Synchronous Latch & 0-Latency FSM
* Read FSM 상태 전환 지점(`r_next_state == READ`)을 타격하여 `s_rvalid`와 `s_rdata`가 동일 클럭 에지에서 동기식으로 동시에 래치되도록 개편하여 정석 **1-Cycle Read Latency**를 구현했습니다.
* Write 대기 방 진입 시 실시간 전선 신호(`s_wvalid`, `s_awvalid` wire)를 Look-ahead 결합하여 지각 신호 도착 즉시 지연 없이 탈출하는 **0-Latency FSM**을 구현했습니다.

### 3. Verification Driver & Deadlock Prevention
* SystemVerilog `fork...join` 병렬 스레드 구동 및 **100-Clock Watchdog Timer**를 구축하여 AXI 비동기 채널 수거 시 시뮬레이션 무한 정지(Hang) 및 데드락을 방지했습니다.
* `@(negedge rst_n)` 이벤트 트랩 탈출 로직을 적용하여 트랜잭션 수행 도중 리셋이 인가되어도 안정적으로 초기 상태로 복귀하는 **Active Reset & Recovery**를 입증했습니다.

---

## 📂 Repository Directory Structure

    ├── README.md               # 📌 메인 대문 (프로젝트 개요 및 아키텍처 요약)
    ├── docs/                   # 📖 상세 엔지니어링 문서 보관소
    │   ├── DevLog.md           # 일자별 개발 및 검증 기록 노트
    │   ├── troubleshooting.md  # RTL/AXI 타이밍 및 프로토콜 트러블슈팅 분석집 (12 Key Issues)
    │   └── waveform_log.md     # Vivado 파형 분석 및 타이밍 검증 아카이브 (10 Waveforms)
    ├── src/                    # RTL 설계 소스 코드 (.v)
    │   ├── uart_baud_gen.v
    │   ├── uart_rx.v
    │   ├── uart_tx.v
    │   ├── uart_top.v
    │   ├── uart_axi_bridge.v
    │   └── axi_lite_slave.v
    ├── tb/                     # SystemVerilog BFM 테스트벤치 (.sv)
    │   ├── tb_uart_tx.sv
    │   ├── tb_uart_top.sv
    │   └── tb_axi_lite_slave.sv
    └── constraints/            # Vivado XDC 제약 파일 (.xdc)

---

## 📖 Detailed Engineering Documentation

설계 및 검증 과정에서 기록한 일자별 일지, RTL 트러블슈팅, 시뮬레이션 파형 분석 리포트는 아래 문서에서 상세히 확인하실 수 있습니다.

* 📖 **[Daily Development Log (docs/DevLog.md)](docs/DevLog.md)**: 날짜별 구현 및 검증 내역
* 🔍 **[Hardware Troubleshooting Notes (docs/troubleshooting.md)](docs/troubleshooting.md)**: 12가지 주요 버그 원인 분석 및 해결 아키텍처
* 📊 **[Waveform Analysis Log (docs/waveform_log.md)](docs/waveform_log.md)**: 10개 핵심 시뮬레이션 파형 정밀 타임라인 검증
