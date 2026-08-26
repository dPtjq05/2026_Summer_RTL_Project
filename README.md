# 🛰️ UART to AXI4-Lite Register Map Controller & BIST Verification System

FPGA (Artix-7 / Cmod A7) 환경에서 12MHz 시스템 클럭을 기반으로 동작하는 고신뢰성 UART IP, AXI4-Lite 레지스터 맵 제어기 RTL 설계 및 C 언어 기반 자가진단(BIST) 엔진 통합 프로젝트입니다.

(본 README 파일은 직접 설계한 코드와 자료를 바탕으로 AI의 도움을 받아 작성하였습니다. 내용은 모두 직접 구성했으며 md 파일의 문법만 참고했음을 알려드립니다.)
---

## 📌 Project Overview

본 프로젝트는 호스트 PC(C Host Driver)와의 UART 직렬 통신 패킷을 수신하여 온칩 **AXI4-Lite 버스 트랜잭션**으로 변환하고, 내부 32비트 레지스터 맵(Register File)을 정밀 제어하며, **C 언어 기반 BIST 엔진**을 통해 하드웨어 데이터 무결성을 자동 검증하는 풀스택 HW/SW Co-Design 시스템입니다.

* **Target Board:** Xilinx Cmod A7-35T (Artix-7 `XC7A35T-1CPG236C`)
* **System Clock:** 12 MHz ($T = 83.33\text{ns}$)
* **Design & Verification:** Verilog HDL, SystemVerilog (Task-based BFM)
* **Software Stack:** C (C99), Custom HAL (`axi_regs.h`), BIST Test Harness
* **EDA Tool:** AMD Xilinx Vivado ML Edition
* **Core Protocols:** UART (9600 bps, 16x Oversampling) $\longleftrightarrow$ AXI4-Lite Slave Protocol

---

## 🏗️ System Architecture

전체 시스템은 호스트 C 드라이버 계층부터 FPGA 내부의 UART Top, UART-to-AXI Bridge, AXI4-Lite Slave 레지스터 뱅크까지 계층적으로 바인딩되어 동작합니다.

    +----------------------------------------------------+
    |  Host PC (C99 Driver / BIST Engine)                |
    |  - Packet Serializer / Deserializer                |
    |  - 3-Pattern BIST (Checkerboard, Walking 1s, Rand) |
    +----------------------------------------------------+
                             │ UART (9600 bps Serial Stream)
                             ▼
    +----------------------------------------------------+
    |  FPGA Top-Level (system_top.v)                     |
    |                                                    |
    |  +-------------------+       +------------------+  |
    |  | UART Top (RX/TX)  | <===> | UART-AXI Bridge  |  |
    |  | - 16x Oversample  | 8-bit | - 32b Shift Concat| |
    |  | - 2-Stage Sync    | Pulse | - 0-Skew AXI FSM |  |
    |  +-------------------+       +------------------+  |
    |                                        │           |
    |                                  AXI4-Lite Bus     |
    |                                        ▼           |
    |                              +------------------+  |
    |                              | AXI4-Lite Slave  |  |
    |                              | - 4-State Write  |  |
    |                              | - 4x 32-bit Regs |  |
    |                              +------------------+  |
    +----------------------------------------------------+

---

## 📋 Protocol & Memory Map Specification

### 1. Host-to-FPGA UART 통신 패킷 규격 (Big-Endian)
* **Write 패킷 (9 Bytes):** `[Opcode: 0x01] [Address: 4 Bytes] [Write Data: 4 Bytes]`
* **Read 요청 패킷 (5 Bytes):** `[Opcode: 0x02] [Address: 4 Bytes]`
* **Read 응답 패킷 (4 Bytes):** `[Read Data: 4 Bytes]`

### 2. AXI4-Lite Memory Map
| Address Offset | Register Name | Type | Reset Value | Description |
| :--- | :--- | :---: | :---: | :--- |
| `0x0000_0000` | `REG_CTRL` | R/W | `0x0000_0000` | 제어 및 동작 모드 설정 레지스터 |
| `0x0000_0004` | `REG_STATUS` | RO | `0x0000_0000` | 시스템 상태 및 버스 상태 플래그 |
| `0x0000_0008` | `REG_DATA_0` | R/W | `0x0000_0000` | 32-bit BIST 자가진단 주 타겟 레지스터 |
| `0x0000_000C` | `REG_DATA_1` | R/W | `0x0000_0000` | 32-bit 범용 데이터 레지스터 |

---

## 🧩 Module Specifications

| 모듈명 / 계층 | 주요 기능 | 적용된 하드웨어 아키텍처 및 특징 |
| :--- | :--- | :--- |
| **`uart_baud_gen`** | 시스템 클럭 분주 및 샘플링 틱 생성 | 12MHz $\rightarrow$ 153.6kHz (분주비 78, 오차율 0.15% 미만), 7-bit Counter |
| **`uart_rx`** | 직렬 데이터를 8-bit 병렬 데이터로 복원 | 16x Oversampling (7th tick 중앙 타격), Registered Output (`rx_done` 1-clock pulse), 2-Stage Sync |
| **`uart_tx`** | 8-bit 병렬 데이터를 직렬 송출 | 2-Block FSM + Combinational MUX 하이브리드 구조 (1-Clock Pipeline Lag 방지, Zero-Latency MUX) |
| **`uart_axi_bridge`** | UART 패킷 $\longleftrightarrow$ AXI4-Lite 버스 변환 | Command Parser ('W'/'R'), Shift Concatenation (32-bit), 0-Skew AXI Signal Driving |
| **`axi_lite_slave`** | AXI4-Lite 응답 및 레지스터 기입 | 4-State Decoupled Write FSM, Zero-Latency Write, 1-Cycle Read Latency, Write Strobe(`wstrb`) |
| **`C Host Driver`** | HAL 추상화 및 BIST 검증 엔진 | Bitwise OR(`\|`) 기반 조립, 명시적 `uint32_t` 캐스팅 부호확장 방지, 가상 루프백 검증 |

---

## 🚀 Key Engineering Highlights

### 1. STA 마진 확보를 위한 2-Block FSM & Zero-Latch Synthesis
* 조합논리(`always @(*)`)와 순차논리(`always @(posedge clk)`)의 역할을 철저히 분리한 2-Block FSM 아키텍처를 적용하여 Combinational Cloud 깊이를 최소화했습니다.
* 조합논리 블록 최상단에 Default Assignment 테크닉을 일괄 적용하여 미정의 경로에 따른 의도치 않은 Latch 합성을 100% 차단했습니다.

### 2. AXI4-Lite 0-Latency Handshake & Zero-Skew 버스 구동
* **Master (Bridge):** `AXI_WRITE` 상태 진입과 동시에 주소, 데이터, 유효 신호(`AWVALID`, `WVALID`)를 동일 클럭 에지에 인가(0-Skew)하여 버스 전송 효율을 극대화했습니다.
* **Slave (Register):** AW/W 독립 채널 대기 상태에서 실시간 신호(`s_wvalid`, `s_awvalid`)를 Look-ahead 결합하여 신호 도착 즉시 0클럭 지연으로 탈출하는 0-Latency FSM을 구현했습니다.

### 3. CDC(Clock Domain Crossing) 방지 및 글리치 억제
* 외부 비동기 `rx` 입력에 **2-Stage Synchronizer (Double Flopping)**를 적용하여 메타스테빌리티(Metastability)를 차단했습니다.
* `Pre-asserted BREADY` 조건에서 발생할 수 있는 Delta Cycle (0ns Glitch) 현상을 분석하고, Moore 스타일 FSM 제어를 확립하여 무한 발진(Oscillation) 버그를 수정했습니다.

### 4. C Host BIST 자동화를 통한 반도체 결함 검출
* **Checkerboard (`0x55555555`, `0xAAAAAAAA`):** 인접 배선 간 간섭(Crosstalk) 및 브릿징 결함 검출.
* **Walking 1s (`0x00000001` $\rightarrow$ `0x01000000`):** 각 비트 라인의 Stuck-at-0 물리 결함 검출.
* **Random Stress:** 임의 데이터 버스 부하 및 래치 안정성 100% PASS 검증.

---

## 🧪 BIST Verification Result

    ===============================================================
      AXI4-Lite Register BIST Engine Run (Target: 0x00000008)
    ===============================================================
     [Checkerboard 0x55   ] Written: 0x55555555 | Read: 0x55555555 -> [ PASS ]
     [Checkerboard 0xAA   ] Written: 0xAAAAAAAA | Read: 0xAAAAAAAA -> [ PASS ]
     [Walking 1s (Bit 00) ] Written: 0x00000001 | Read: 0x00000001 -> [ PASS ]
     [Walking 1s (Bit 08) ] Written: 0x00000100 | Read: 0x00000100 -> [ PASS ]
     [Walking 1s (Bit 16) ] Written: 0x00010000 | Read: 0x00010000 -> [ PASS ]
     [Walking 1s (Bit 24) ] Written: 0x01000000 | Read: 0x01000000 -> [ PASS ]
     [Random Pattern 1    ] Written: 0x7A3F109C | Read: 0x7A3F109C -> [ PASS ]
     [Random Pattern 2    ] Written: 0x1B89CDEF | Read: 0x1B89CDEF -> [ PASS ]
     [Random Pattern 3    ] Written: 0x4D2088AA | Read: 0x4D2088AA -> [ PASS ]
    ===============================================================
      Result: 9 / 9 Vectors Passed (100% Integrity Verified)
    ===============================================================

---

## 📂 Repository Directory Structure

    ├── README.md               # 📌 메인 대문 (프로젝트 개요 및 아키텍처 요약)
    ├── docs/                   # 📖 상세 엔지니어링 문서 보관소
    │   ├── DevLog.md           # 일자별 개발 및 검증 기록 노트 (2026.06.29 ~ 08.24)
    │   ├── troubleshooting.md  # RTL/AXI 타이밍 및 프로토콜 트러블슈팅 분석집 (12 Key Issues)
    │   └── waveform_log.md     # Vivado 파형 분석 및 타이밍 검증 아카이브 (10 Waveforms)
    ├── src/                    # RTL 설계 소스 코드 (.v)
    │   ├── system_top.v        # 4-pin 인터페이스 최상위 모듈
    │   ├── uart_baud_gen.v
    │   ├── uart_rx.v
    │   ├── uart_tx.v
    │   ├── uart_top.v
    │   ├── uart_axi_bridge.v
    │   └── axi_lite_slave.v
    ├── tb/                     # SystemVerilog BFM 테스트벤치 (.sv)
    │   ├── tb_uart_top.sv
    │   ├── tb_bridge.sv
    │   └── tb_axi_lite_slave.sv
    ├── driver/                 # 💻 C 언어 HAL 및 BIST 소프트웨어 (.c, .h)
    │   ├── axi_regs.h          # Hardware Abstraction Layer & Register Offset
    │   └── host_cli.c          # Packet Builder & BIST Verification Engine
    └── constraints/            # Vivado XDC 제약 파일 (.xdc)
        └── Cmod-A7-Master.xdc

---

## 📖 Detailed Engineering Documentation

* **[📖 Daily Development Log (`docs/DevLog.md`)](docs/DevLog.md):** 날짜별 RTL 구현, 시뮬레이션 및 검증 내역 전문
* **[🔍 Hardware Troubleshooting Notes (`docs/troubleshooting.md`)](docs/troubleshooting.md):** 12가지 주요 버그 원인 분석(RCA) 및 해결 아키텍처
* **[📊 Waveform Analysis Log (`docs/waveform_log.md`)](docs/waveform_log.md):** Vivado 핵심 파형 정밀 타임라인 검증 리포트
