# 2026_Summer_RTL_Project

# 🛰️ UART to Register Map Controller IP Design

> **FPGA (Artix-7 / Cmod A7) 환경에서 12MHz 시스템 클럭을 기반으로 동작하는 고신뢰성 UART IP 및 AXI4-Lite 기반 레지스터 맵 제어기 설계 프로젝트입니다.**

---

## 📅 Week 1: UART 통신 코어 아키텍처 설계 및 검증 완료

외부의 비동기 신호를 안전하게 받아들이는 수신기(RX)와 내부 동기 신호를 표준 규칙에 맞춰 밀어내는 송신기(TX)의 뼈대를 완성하고, 하드웨어 타이밍 마진을 제어하는 정석 아키텍처를 수립했습니다.

### 🚀 1. 주요 개발 성과 (Key Achievements)
* **실무 표준 개발 환경 최적화**
  * Vivado 도구가 생성하는 무분별한 임시 파일로 인한 원격 저장소 오염을 방지하기 위해 `src/`(설계), `tb/`(검증), `vivado_prj/`(작업 공간) 구조를 정형화하고 `.gitignore` 최적화 완료.
* **고신뢰성 Baud Rate Generator 설계**
  * 입력 클럭 12MHz 환경에서 9,600bps 목표 보레이트(16x 오버샘플링)를 위한 정확한 분주비 **78** 도출 (12MHz ÷ 153,600Hz = 78.125 ≈ 78).
  * 오차율 0.15% 미만의 7비트 분주 카운터(`reg [6:0]`) 구현 및 검증 완료.
* **16x 오버샘플링 기반 UART RX Core 구현**
  * 시작 비트 정중앙(7번째 틱) 및 데이터 비트 정중앙(16번째 틱 간격)을 정밀 타격하는 샘플링 제어 로직 완성.
  * 조합회로 글리치(Glitch) 차단을 위해 출력단에 **Registered Output(쌍둥이 레지스터) 구조**를 적용하여, 수신 완료 깃발(`rx_done`)이 정확히 1 시스템 클럭 주기(83.33ns) 동안만 튀어 오르는 깨끗한 펄스로 제어 성공.
* **UART TX Core FSM 아키텍처 수립**
  * `IDLE` ➡️ `START` ➡️ `DATA` ➡️ `STOP`으로 이어지는 정석 **2-Block FSM 구조** 설계 완료.

### 🔍 2. 핵심 디버깅 및 하드웨어적 깨달음 (Critical Troubleshooting & Insights)
* **🚨 마지막 데이터 비트(Data 7) 유실 버그 해결**
  * **문제 상황:** RX `DATA` 상태방에서 마지막 인덱스(`3'd7`)의 15번째 틱 정중앙에 도달했을 때, 분기문 조건 우선순위로 인해 정작 중요한 마지막 비트 데이터를 임시 상자에 밀어 넣는 우측 시프트 연산(`next_data = {rx, current_data[7:1]};`)이 씹힌 채 `STOP` 방으로 튕겨 나가는 타이밍 버그 발생.
  * **해결 아키텍처:** 하드웨어 데이터 경로(Datapath)를 역추적하여, 몇 번째 비트든 "15번째 틱에서는 예외 없이 데이터를 시프트해야 한다"는 공통 분모를 도출. **시프트 연산 라인을 조건 분기문 직전(상단)으로 추출(Extract)**하여 연산이 물리적으로 차단되지 않도록 구조 정렬 완료.
* **🚨 클럭 도메인(Clock Domain)에 따른 신호 제어 전략**
  * **Asynchronous (외부 영역):** 외부 `rx`선은 야생의 비동기 신호이므로 노이즈 마진 확보와 정중앙 타격을 위해 **16배수 오버샘플링 메커니즘**을 필수로 적용.
  * **Synchronous (내부 영역):** 반면 TX 모듈의 출발 신호탄인 `tx_start`는 시스템 클럭(12MHz)에 완벽히 동기화된 안전한 내부 신호이므로 오버샘플링이 필요 없음.
  * **치명적 버그 방어:** 만약 `tx_start` 신호의 유지가 너무 길면, TX FSM이 한 바이트를 다 쏘고 `IDLE`로 돌아왔을 때도 여전히 신호가 켜져 있어 **무한 연사(Multi-triggering) 버그**가 발생함. 따라서 `tx_start`는 정확히 **1클럭 주기(83.33ns)** 동안만 번쩍 켜지는 펄스(Pulse) 형태로 제어해야 함을 타이밍 관점에서 이해하고 설계에 반영.
* **🚨 임계 경로(Critical Path) 방지를 위한 2-Block FSM 도입**
  * 단일 마스터 카운터 하나만으로 수천 클럭을 세며 제어하려 하면, 가산기와 비교기가 복잡하게 얽혀 조합회로 구름이 깊어짐. 이는 12MHz 시스템 주기의 상한선인 **83.33ns** 제한을 초과하여 셋업 타임 위반(Setup Time Violation)을 일으킬 위험이 큼.
  * 이를 방지하기 위해 회로를 4개의 상태방으로 쪼개고, 각 방 내부에서는 고작 0 ~ 15까지만 세는 **얇은 4비트 로컬 카운터만 동작**하게 만들어 타이밍 슬랙(Slack, 여유 시간)을 압도적으로 확보함.

---

## 📅 개발 로그: 2026년 6월 29일 (월)

### 🎯 오늘 달성한 목표
- `uart_tx.v` FSM 구현 완료 (`DATA` 상태 및 `STOP` 상태 로직 완성)
- 2-Block FSM 구조의 조합회로 피드백 루프 및 래치 방어 메커니즘 수립
- UART TX 단독 검증(Unit Test)을 위한 테스트벤치(`tb_uart_tx.v`) 설계 및 시뮬레이션 환경 구축

### 🛠️ 핵심 하드웨어 아키텍처 및 설계 철학
* **2-Block FSM 구조에서의 조합회로 루프(Feedback Loop) 방지**
  * 조합회로 블록(`always @(*)`) 내에서 카운터 변수(`bit_data_cnt`)가 자기 자신을 직접 참조하여 연산할 경우, 클럭 에지가 치기 전 찰나의 순간에 무한 전압 발산(Combinational Loop)이 발생하는 치명적인 결함 차단.
  * 이를 방지하기 위해 계산용 전선 역할을 하는 `next_bit_data_cnt`와 진짜 하드웨어 저장소인 `bit_data_cnt`로 **전선과 플립플롭을 철저히 분리(Current/Next 쌍)**하여 설계. 조합회로의 실시간 연산 결과가 오직 정밀한 클럭 상승 에지(`posedge clk`) 타이밍에만 동기화되어 안전하게 문을 닫고 들어가도록 제어함.
* **의도치 않은 래치(Unintended Latch) 방어막 형성**
  * 조합회로 특성상 특정 조건(`if`) 외의 경우(`else`)에 대해 변수 상태를 정의하지 않으면, 이전 값을 기억하기 위해 타이밍을 파괴하는 래치가 합성되는 결함 인지.
  * 이를 해결하기 위해 `always @(*)` 블록 최상단에 **상단 기본값 선언(Default Assignment)** 테크닉을 적용. 베릴로그의 "가장 마지막에 덮어쓴 값이 법이 되는(Last-Writer-Wins)" 규칙을 활용하여 무수히 지저분한 `else` 코드를 싹 걷어내고 완벽한 멀티플렉서(MUX) 하드웨어 스위치 구조로 변신시킴.

### 🔍 Verification & Testing Strategy (검증 전략)
* **Bottom-Up 방식의 단독 검증(Unit Test) 우선 원칙**
  * TX와 RX를 처음부터 조립하는 통합 검증(Loopback)을 수행할 경우 버그 발생 시 디버깅 범위가 비대해지므로, "쪼개서 정복하라(Divide and Conquer)"는 원칙에 따라 먼저 송신기(`uart_tx.v`)가 규격에 맞게 뿜어내는지 단독 검증 시나리오 기획.
* **다이내믹 데이터 인젝션(Dynamic Data Injection) 교란 시나리오**
  * TX 모듈이 스타트 신호(`tx_start`)가 인가되는 정밀한 상승 에지 타이밍에만 외부 데이터를 정확히 가두는지(Latch) 검증하기 위한 교란 작전 설계.
  * **시나리오:** `tx_start` 펄스 시점에는 `8'hAA` 주입 ➡️ 전송이 한창 진행 중인 데이터 프레임 중간에 외부 전선 데이터(`tx_data`)를 의도적으로 `8'hFF`로 오염시킴.
  * **합격 기준:** 외부 전선이 오염되더라도 TX 내부 레지스터(`tx_data_reg`)가 최초의 데이터 `8'hAA`를 프레임 종료 시까지 완벽히 홀딩하고, 출력선(`tx`)으로 무결한 직렬 파형이 나가는지 검증 후 통과.
* **시뮬레이션 환경 (Time Scale: 1ns / 1ps)**
  * **보레이트 속도:** 9600 bps (1비트당 약 104.16us)
  * **1프레임 총 전송 시간:** `START(1) + DATA(8) + STOP(1) = 10비트` ➡️ 최소 **1.04ms** 소요.
  * **시뮬레이션 가동 시간:** 복귀 및 완충 구간 확인을 위해 정확히 **`1.2 ms` (`1200 us`)** 타임 설정 후 시뮬레이터 가동 준비 완료.

---

## 📅 진행 상황 (2026-07-02)

### 🎯 오늘 달성한 목표
* **UART TX/RX 통합 모듈(Top-Level) 구현 및 루프백 검증 성공**
  * 앞서 단독 검증된 RX 모듈과 TX 모듈을 하나의 최상위 모듈(`uart_top.v`)로 패키징하고, 내부 루프백(Loopback) 데이터 패스 구축.
  * 테스트벤치에서 임의의 바이트 데이터를 입력했을 때, `RX ➡️ 내부 버퍼 ➡️ TX`를 거쳐 결괏값이 단 1비트의 유실 없이 그대로 복사되어 출력되는지 통합 검증 완료.
  * 보레이트 제너레이터(Baud Rate Generator) 오버샘플링 클럭과 실제 시리얼 데이터의 토글 타이밍 마진이 완벽히 일치함을 파형 분석을 통해 확인.

---

## 📅 진행 상황 (2026-07-08)

### 🏗️ 1. 아키텍처 구조 개선 (3-State FSM ➡️ 4-State FSM)
초기 설계 단계에서 발생한 제어 복잡성을 해결하기 위해 FSM(Finite State Machine)의 구조적 리팩토링을 단행했습니다.
* **기존 구조 (3-State FSM):** `WIDLE` ➡️ `WRITE` ➡️ `WRESP`
  * 주소 채널(AW)하고 데이터 채널(W)의 신호가 서로 엇갈려 들어오는 예외 상황을 처리하기 위해 내부 플래그 레지스터(`a_cap`, `d_cap`)를 추가로 도입해야 했습니다. 이로 인해 코드의 가독성이 떨어지고 불필요한 우선순위 로직(Priority Logic)이 형성되었습니다.
* **개선 구조 (4-State FSM):** `WIDLE` ➡️ `WDATA_WAIT` / `WADDR_WAIT` ➡️ `WRESP`
  * "현재 FSM이 머무르는 상태(State) 자체가 곧 과거의 기억"이 되도록 설계하여 **기존의 플래그 레지스터(`cap` 변수들)를 100% 제거**했습니다. 각 채널이 독립적으로 지각생 신호를 기다리는 전용 방으로 분리되어 자원 복잡도를 낮추고 완벽한 채널 독립성을 달성했습니다.

### 🔍 2. 타이밍 디버깅 및 트러블슈팅 (Troubleshooting)
* **🚨 [Issue #01] 대기 상태에서의 1-Clock 레이턴시 버블(Latency Bubble) 해결**
  * **문제 상황:** 주소나 데이터 중 하나가 먼저 도착하여 대기 방에서 지각생 신호를 기다릴 때, 나머지 신호가 들어왔음에도 불구하고 다음 상태(`WRESP`)로 즉시 전이되지 못하고 대기 방에 1클럭 더 머무는 정체 현상 식별.
  * **원인 분석:** 조합 회로(Next State Logic)의 상태 천이 조건문이 순차 회로의 출력인 레지스터 변수들로만 구성되어 있어 발생한 문제. 레지스터는 클럭 에지 이후에 값이 갱신되므로, 현재 클럭 주기 내에 도달한 실시간 핸드셰이크를 즉시 인지하지 못해 1클럭의 지연 패널티가 발생함.
  * **해결 방법:** 조합 회로의 천이 조건에 레지스터뿐만 아니라, 현재 버스에 인가되고 있는 마스터의 실시간 전선 신호(`s_wvalid`, `s_awvalid` wire)를 논리곱(AND)으로 결합. 레지스터 동기화 딜레이를 제거하고, 지각 신호가 도착한 바로 그 클럭 에지에서 즉시 `WRESP` 상태로 탈출하는 **'0클럭 지연(Zero-Latency)'** 고속 FSM을 구현함.
* **🚨 [Issue #02] 조합 회로 내 출력 제어로 인한 핸드셰이크 파괴 오류 수정**
  * **문제 상황:** 지각생 신호가 들어오는 순간 분기문 내부에서 READY 신호를 강제로 내리도록 설계하자, 마스터와의 악수 자체가 무산되는 치명적인 교착 상태(Deadlock) 위험성이 인지됨.
  * **원인 분석:** 2-Block FSM 구조에서 조합 회로(`always @(*)`) 내부의 조건문은 전압의 변화에 따라 클럭 에지 전이라도 실시간으로 반응함. 마스터가 `VALID=1`을 켜자마자 슬레이브의 조합 회로가 `READY=0`으로 신호를 떨어뜨리면서, 정작 중요한 클럭 상승 에지 시점에는 핸드셰이크 조건이 깨지는 인과관계의 오류였음.
  * **해결 방법:** 상태 내의 지엽적인 조건문 안에서 출력을 강제로 제어하는 위험한 코드를 모두 제거. `READY` 신호의 제어는 상단의 기본값 제어와 FSM의 최상위 상태 전환(State Transition)에 완벽히 위임(Decoupling)하여 안전성을 확보함.

### 💡 3. 핵심 하드웨어 설계 원칙 준수
* **동기식 설계 (Synchronous Design)의 본질 준수**
  * 조합 회로는 오직 방향지시등(`w_next_state`)하고 실시간 전선 신호만 제어하고, 실제 내부 레지스터(`buf_awaddr`, `buf_wdata`)에 값을 가두고 잠금(Lock)하는 행위는 철저히 클럭 에지를 타는 순차 회로(`always @(posedge clk)`)에만 위임하여 래치 발생 가능성을 근본적으로 차단함.
* **독립 채널의 병렬 처리 (Parallel Processing)**
  * AXI 프로토콜의 대원칙인 '주소/데이터 채널의 독립성'을 보장하기 위해, 순차 회로 내부에서 불필요한 우선순위 로직을 걷어내고 독립된 2개의 `if`문으로 병렬 배치하여 물리적으로 완벽히 독립된 클럭 인에이블(Clock Enable) 제어 루프를 형성함.

---

## 📅 진행 상황: 2026년 7월 9일 (목)

### 🎯 오늘 달성한 목표
- AXI4-Lite Slave 쓰기 데이터 스트롭(`wstrb`) 제어 로직 설계 및 구현 완료.
- 데이터 선입력 시 발생할 수 있는 가비지 데이터 오염 차단 알고리즘 수립 및 4-State FSM 대기 상태 최종 결합 완료.

### 🔍 핵심 디버깅 및 하드웨어적 깨달음 (Critical Troubleshooting & Insights)
* **🚨 쓰기 스트롭 도입에 따른 쓰레기 값(Garbage) 오염 리스크 방어**
  * **문제 상황:** 데이터 채널이 먼저 활성화되어 `WADDR_WAIT` 상태로 진입할 때, 일부 바이트만 유효한 상태(`wstrb`가 특정 비트만 켜진 경우)에서 나머지 상위 바이트의 가비지 데이터가 임시 버퍼에 남게 됨. 이 상태로 지각한 주소가 도착하면 진짜 레지스터의 멀쩡한 데이터를 덮어써 파괴하는 타이밍 함정 식별.
  * **해결 아키텍처:** 데이터 버퍼(`buf_wdata`)와 쌍을 이루는 4-bit 스트롭 버퍼 레지스터(`buf_wstrb`)를 신규 도입. 데이터가 먼저 도착하는 시점에 스트롭 신호등도 함께 가두어 두었다가, 주소 전선이 인가되는 타이밍에 유효 바이트 신분증을 대조하도록 설계하여 오염 원천 차단. 두 대기 방의 재료(전선 vs 버퍼) 관계를 매핑하여 구조적 일관성(Structural Consistency) 확보 성공.

### 💡 하드웨어 최적화 관점 (Synthesis & PPA Optimization)
* **Clock Enable (CE) 핀 직결 및 0-Mux 트리 최적화**
  * 스트롭 변수의 16가지 유효 조합을 이중 `case`문으로 설계할 경우 발생하는 조합 논리 게이트의 폭발적 증가와 타이밍 패널티 문제를 인지.
  * 큰 갈래는 주소 `case`문으로 묶되, 내부 사물함 제어는 **4개의 독립된 바이트 단위 `if`문**으로 수평 배치함.
  * 이를 통해 합성기(Synthesizer)가 데이터 경로상에 불필요한 거대 Mux 트리를 생성하는 것을 방지하고, 주소 디코딩 결과와 스트롭 신호가 플립플롭의 물리적 쓰기 제어 핀(`CE` / `WE`)에 최단 거리로 직결되도록 유도함. 결과적으로 임계 경로(Critical Path) 딜레이를 최소화하여 최대 동작 주파수($F_{max}$) 마진을 극적으로 사수함.

---
## 📝 7월 17일: Register Map 및 AXI4-Lite Slave IP 설계

### 1. Write Channel FSM 및 Zero-Latency Write 아키텍처

- **FSM State 구조**: `WIDLE` ➡️ `WADDR_WAIT` / `WDATA_WAIT` ➡️ `WRESP` 단계로 세분화하여 주소와 데이터가 비동기적으로 도착하는 예외 상황 통제.
- **Zero-Latency Write**: 일반적인 1-Clock Delay 버퍼링 기입 대신, 주소 및 데이터 핸드셰이크가 완료되어 `WRESP`로 전이하는 상승 에지(Edge) 순간에 내부 Register File(`slv_reg_0`~`3`)에 즉시 쓰기를 완료하는 최적화 구현.
- **Write Response (WRESP) 제어**: 대기 상태가 아닌 `WRESP` 상태 내부에서 마스터의 `s_bready` 신호를 확인하고 동기식으로 `s_bvalid` 신호를 릴리즈하여 완벽한 버스 릴레이션 및 데드락 방지 보장.

### 2. Read Channel 설계 및 독립 채널 구조 (Split Transaction) 분석

- **FSM State 구조**: 주소를 처리하는 `RIDLE` 상태와 데이터를 반환하는 `RDATA` 상태의 초간결 2-State FSM 구조 확립.
- **독립 채널 구조 (Decoupled Channels)**: AXI 프로토콜 스펙에 의거하여 AR(Address Read) 채널과 R(Read Data) 채널을 완전 비동기로 분리 설계.
- **Latency 은닉 및 버스 효율 최적화**: 주소 캡처와 데이터 출력을 분리하여 물리적 메모리 읽기 지연(Latency)을 은닉하고, 마스터가 데이터를 채가기 전 다음 주소를 선입력받을 수 있는 파이프라이닝(Outstanding) 대역폭 확보.

### 3. 하드웨어 타이밍 마진 및 검증 포인트

- **2-Block FSM 스타일**: 조합회로(`always @(*)`)와 순차회로(`always @(posedge clk)`)의 역할을 철저히 이원화하여 합성기(Synthesizer)의 래치(Latch) 생성을 원천 차단.
- **Registered Output 의사결정**: 버스 출력 신호(`s_bvalid`, `s_bresp`)를 제어할 때 조합회로 출력과 물리적 D-FF(Registered) 출력의 정적 타이밍 분석(STA) 관점에서의 $T_{co}$ 마진 및 글리치(Glitch) 차단 효과 분석 완료.

---
## 📝 7월 21일: AXI4-Lite Slave Testbench 구축 및 Write Channel Corner Case 검증

### 1. Task 기반 BFM Testbench 아키텍처 및 모듈화

- **Task 기반 BFM(Bus Functional Model) 아키텍처**: AXI4-Lite 트랜잭션을 제어하는 신호 구동 로직을 독립된 `task` 구문으로 분리 및 모듈화하여, 테스트벤치 코드 가독성 극대화 및 재사용 가능한 Verification Driver 구축.
- **Self-Checking 자동화 검증**: 시뮬레이션 파형(Waveform)을 일일이 확인하는 대신, Task 내부에서 `s_axi_bresp` 신호 및 읽기 데이터를 수치 검증하여 `$display` / `$error`로 결과를 자동 출력하는 Self-checking 메커니즘 내장.
- **5단계 정석 Testbench 파이프라인**: Timescale/신호 선언 ➡️ Clock/Reset 생성 ➡️ DUT 인스턴스화 ➡️ Driver Task 정의 ➡️ Scenario 실행의 5단계 정석 구조를 적용하여 시뮬레이션 환경의 높은 신뢰성 확보.

### 2. Write 채널 타이밍 코너 케이스 (3가지 비동기 시나리오) 검증

- **동시 주입 시나리오 (Simultaneous Write)**: 동일한 클럭 에지에서 `s_axi_awvalid`와 `s_axi_wvalid`를 동시 Assert하여, 슬레이브의 표준 핸드셰이크 처리 및 정상 기입 동작 검증.
- **주소 선행 주입 시나리오 (Address-First Write)**: `s_axi_awvalid` 주입 후 `repeat (3) @(posedge clk)` 구문을 활용해 3클럭 지연(Delay)을 발생시킨 뒤 `s_axi_wvalid`를 주입하여, 슬레이브 내부 주소 버퍼링 및 데이터 대기 FSM 동작 검증.
- **데이터 선행 주입 시나리오 (Data-First Write)**: `s_axi_wvalid`를 먼저 주입하고 3클럭 지연 후 `s_axi_awvalid`를 주입하여, 데이터 사전 버퍼링 및 주소 도착 순간 즉시 쓰기가 완결되는 비동기 독립 채널 수거 동작 완벽 입증.

### 3. 병렬 수거(`fork...join`) 및 하드웨어 타이밍 동기화

- **`fork...join` 병렬 스레드 구동**: 물리적으로 분리된 AW 채널과 W 채널의 핸드셰이크 수거 로직을 독립 스레드로 동시 실행하여, 슬레이브의 `ready` 응답 순서에 구애받지 않고 데드락(Deadlock) 없이 안전하게 핸드셰이크 완결.
- **Level/Edge 2단계 동기화 메커니즘**: `wait(ready)`를 통한 전압 레벨(Level) 감지 후, `@(posedge clk)`를 결합해 슬레이브 플립플롭이 데이터를 완전히 캡처(Latch)하는 상승 에지 시점까지 명시적으로 대기하는 정석 동기화 구현.
- **레이스 컨디션(Race Condition) 차단**: 클럭 에지 직후 Non-blocking 연산자(`<= 1'b0`)를 사용해 `s_axi_valid` 신호를 Deassert함으로써, 시뮬레이터 상의 경쟁 상태 버그를 차단하고 실제 하드웨어의 $T_{su}$ / $T_{h}$ (Setup/Hold Time) 타임라인 동작을 정확히 모사.

---

## 📝 07월 22일: AXI4-Lite Write BFM 고도화 및 Deadlock 방지 검증 환경 구축

### 1. B Channel (Write Response) 핸드셰이크 통합
* **기능 구현:** AXI4-Lite Complete Write Transaction 완성을 위해 `BVALID` 수신 감지 및 `BREADY` 펄스 제어 로직 추가
* **프로토콜 준수:** `AW`/`W` 핸드셰이크 완료 ➔ `BVALID` 대기 ➔ `BREADY` 응답 전송 순서를 보장하여 AXI4-Lite 의존성 규격 성립

### 2. Watchdog 타이머 기반 Deadlock (Simulation Hang) 방지
* **문제 배경:** RTL 버그로 인해 `ready`/`valid` 신호가 미출력될 경우 시뮬레이터가 `wait()` 구문에 무한히 갇히는 현상 차단 필요
* **개선 사항:** `fork...join_any` 구조 기반의 100-clock Watchdog 타이머 스레드를 구축하여, 타임아웃 발생 시 에러 출력 및 신호 초기화 (`valid=0`, `ready=0`) 후 안전 탈출

### 3. SystemVerilog (`.sv`) 마이그레이션 & 클럭 동기화
* **환경 전환:** `fork...join_any` 및 `disable fork` 등 고급 검증 키워드 활용을 위해 테스트벤치 환경을 SystemVerilog(`.sv`)로 전환
* **타이밍 안정성:** Task 호출 시점의 `@(posedge clk)` 클럭 엣지 동기화를 적용하여 Race Condition 방지

---

## 📝 07월 27일: AXI4-Lite Slave B Channel FSM 디버깅 및 Delta Cycle Glitch 해결

### 1. Delta Cycle (0ns Glitch) 및 Pre-asserted BREADY Overwrite 분석
* **문제 현상:** Testbench의 `wait(bvalid)` 구문은 통과하여 `bready`가 1로 전환되었으나, Waveform 창에서는 `bvalid`가 계속 0으로 표시되는 유령 신호 현상 발생
* **원인 규명:** Master가 `bready=1`을 미리 유지(Pre-assertion)한 상태에서, Non-blocking 할당(`<=`) 및 FSM 조건 판단이 엇갈려 동일 타임스탬프(Delta Cycle) 내에 `bvalid`가 1로 평가된 즉시 0으로 덮어씌워짐 (Waveform에는 최종 Settled Value인 0만 렌더링됨)

### 2. 2-Block FSM 구조 개편 및 BVALID 래치 보장
* **순차 논리 제어:** `bvalid` 및 `bresp` 제어를 `always_ff` 블록 내 레지스터 래치 구조로 완전 전환하여, 핸드셰이크 전까지 최소 1클럭 동안 신호 High 상태가 단단하게 유지되도록 보장
* **상태 전이(Next State) 조건 수정:** Master가 `bready=1`을 미리 올리고 있더라도 `s_bvalid`가 실제 1로 올라오기 전까지 FSM이 `WRESP` 상태에 머물도록 `always_comb` 내 탈출 조건을 `(s_bvalid && s_bready)`로 엄격화

### 3. AXI4-Lite Write Transaction 최종 검증
* **프로토콜 검증:** Handshake 시점에 AXI4-Lite 표준 정상 완료 코드인 `BRESP = 2'b00` (OKAY)이 정상 전달됨을 확인
* **파형 검증:** 45ns~55ns 클럭 구간에서 `bvalid=1`과 `bready=1`이 동시 성립하는 1-clock Handshake 펄스가 Waveform상에 차분하게 렌더링되며 Complete Write Transaction 성공

---

## 📝 07월 28일: Testbench Delay Case 대응 및 2-Block FSM 조합 논리 출력 최적화

### 1. Testbench 신호 미초기화(X 상태) 제거 및 Handshake De-assertion 적용
* **문제 현상:** 주소/데이터 지연(Delay) 테스트 진행 시, FSM이 `0 -> 2 -> 3 -> 0 -> 2` 형태로 비정상 널뛰기(State Toggling)를 반복하며 트랜잭션이 꼬이는 현상 발생.
* **원인 규명:** 
  1. Testbench $0\text{ns}$ 시점에 `bready`, `awvalid` 등의 신호가 초기화되지 않아 `X` (Unknown) 상태가 FSM 판단 로직에 전파됨.
  2. Data Handshake(`wvalid && wready`) 완료 직후 Master가 `wvalid`를 꺼주지 않아(De-assertion 누락), Slave FSM이 "새로운 데이터가 또 들어왔다"고 착각하여 상태 재진입 발생.
* **해결 조치:**
  * Testbench `initial` 블록 시작 시점($0\text{ns}$)에 모든 Master 입력 신호를 `0`으로 명확히 초기화.
  * Handshake 성공 직후 다음 클럭 에지에서 `valid` 신호를 `0`으로 즉시 내려주는 "1-Shot 법칙" 적용.

### 2. TB `fork ... join` 병렬화 구조 개편을 통한 Deadlock 방지
* **문제 현상:** Address와 Data 채널 사이에 Intentional Delay를 부여했을 때, Testbench가 `wait(bvalid)` 줄까지 내려오지 못하고 상위 구문에서 무한 대기(Deadlock)하는 현상 발생.
* **원인 규명:** 순차적 `wait` 구문 작성 시, 비동기로 먼저 완료된 채널의 Handshake 시점을 Testbench가 놓치고 멈춰버림.
* **해결 조치:** 
  * Testbench Task 내에서 **"지연 생성(`repeat`) + 신호 쏘기 + Handshake 대기(`wait`)"** 과정 전체를 Address 채널과 Data 채널로 분리하여 `fork ... join` 병렬 스레드로 재구축.
  * 채널 도착 순서와 지연 시간에 관계없이 두 채널 핸드셰이크가 완결된 후 B 채널 대기로 안전하게 진입하도록 보장.

### 3. 2-Block FSM 조합 논리 출력 제어 (1-Clock Pulse Glitch 제거)
* **문제 현상:** Slave가 `WRESP` 상태로 정상 진입했으나, Master의 `bready` 응답을 기다리지 않고 `bvalid` 신호가 1클럭 만에 `0`으로 떨어지는 프로토콜 위반 발생.
* **원인 규명:** 이전 상태(`WAIT_ADDR`)의 전환 조건문(`if(awvalid && awready)`) 내부에서 `s_bvalid = 1'b1`을 할당했던 Mealy 스타일 설계 오류. 조건 충족 순간(1클럭)에만 출력되고, 실제로 `WRESP` 상태에 도달했을 때는 출력이 디폴트(`0`)로 돌아감.
* **해결 조치:**
  * 정석 2-Block FSM (Moore 스타일) 적용: 조건문 내부에서의 출력 할당을 제거하고, `always_comb` 내에서 오직 **현재 상태(`curr_state == WRESP`)**일 때만 `s_bvalid = 1'b1`을 출력하도록 개편.
  * Master가 `bready=1`을 올려 핸드셰이크가 성사될 때까지 `bvalid` 신호가 꺼지지 않고 수평 유지(Hold)됨을 확인.

### 4. Write Transaction 완전성 및 Handshake 종료(Teardown) 최종 검증
* **Handshake 완결:** `bvalid=1` 유지 상태에서 Master의 `bready=1` 수신 시 1-clock Handshake 정상 완결.
* **Teardown & 복귀 검증:** Handshake 직후 다음 클럭에서 `bvalid`와 `bready`가 동시에 `0`으로 차분하게 떨어지며, FSM이 `IDLE` 상태로 복귀함과 동시에 `awready`, `wready`가 `1`로 재활성화(다음 트랜잭션 대기 상태)됨을 확인.
* **데이터 보존:** 트랜잭션 종료 후에도 내부 버퍼 레지스터(`buf_wdata`)에 수신 데이터가 정합성 있게 유지됨을 Waveform으로 최종 입증.

---

## 📝 07월 29일: AXI4-Lite Write Channel 코너 케이스 정복 및 Read Channel RTL 설계/검증 진입

### 1. Write Channel 코너 케이스 및 예외 처리 완벽 검증

* **AW 채널 선행 지연 검증 (Address-first Case)**
  * 주소가 데이터보다 먼저 입력되는 비동기 시나리오에서, 슬레이브 내부 주소 버퍼가 주소를 정상적으로 래치(Latch)함을 확인.
  * 늦게 도달하는 데이터 채널(`W`)이 인가될 때까지 B 채널 응답 신호(`s_bvalid`)가 섣불리 튀어 오르지 않도록 **프로토콜 억제(Suppress) 동작** 완벽 입증.

* **Response Backpressure (bready 3클럭 지연) 검증**
  * 마스터의 응답 수신 준비 신호(`s_bready`)가 3클럭 동안 지연되는 백프레셔(Backpressure) 상황 연출.
  * 슬레이브가 `s_bvalid` 신호를 흔들림 없이 고정(Hold)하고, 마스터의 핸드셰이크 시점에 차분하게 신호를 해제하는 타이밍 안정성 확인.

* **Back-to-Back 연속 쓰기 & 1-Bubble Cycle 최적화**
  * 연속 쓰기 요청 시 트랜잭션 사이의 공백(Bubble Cycle)을 **1클럭**으로 극단까지 압축하여 최대 처리량(Throughput) 확보.
  * 파이프라이닝 상태에서 이전 데이터 버퍼를 덮어쓰거나 오염시키는 상호 간섭(Interference) 버그가 발생하지 않음을 검증 완료.

* **🚨 [Troubleshooting] 동작 중 Reset 및 Level Wait Trap 해결**
  * **문제 현상:** 트랜잭션 수행 도중 비동기 리셋(`rst_n`)이 인가될 때, Testbench 내부의 레벨 감지 대기 구문(`wait(ready)`)이 영원히 깨어나지 않고 무한 대기(Simulation Hang)에 빠지는 현상 발생.
  * **원인 규명:** 슬레이브가 리셋되어 `ready` 신호를 내렸으나, Testbench 스레드가 리셋 이벤트를 감지하지 못하고 레벨 변화만 대기하다 갇혀버림.
  * **해결 조치:** Testbench Task 내부 핸드셰이크 대기 로직에 `negedge rst_n` 이벤트를 조건으로 결합하여, 리셋 발생 시 대기 트랩을 즉시 강제 탈출하도록 개편.
  * **복구 검증:** 트랜잭션 도중 리셋이 들어와도 버퍼 데이터 즉시 소거(Clear), FSM IDLE 상태 강제 복귀, 리셋 해제 후 다음 트랜잭션을 깔끔하게 정상 수신하는 **Active Reset & Recovery** 메커니즘 완벽 입증.

### 2. Read Channel RTL 설계 및 검증 진입

* **Read Channel 2-Block FSM RTL 구현 완료**
  * AXI4-Lite 규격에 준수하여 AR(Read Address) 채널 및 R(Read Data/Resp) 채널 제어 로직 설계.
  * 조합회로(`always_comb`)와 순차회로(`always_ff`)를 철저히 분리한 **Read 2-Block FSM 구조** 구축.

* **Testbench Task 모듈화 및 Verification Environment 확장**
  * SystemVerilog Read Task 설계 시 `output` 파라미터를 적용하여, 슬레이브로부터 읽어온 데이터를 Task 반환값으로 수거하는 모듈화 완료.
  * 읽어온 데이터와 기대값(Expected Data)을 자동으로 대조/검증하는 Self-checking 구조 정립 후 Common Case 시뮬레이션 진입.

---

## 📝 07월 30일: Read Channel 타이밍 버그 해결 및 AXI RRESP 프로토콜 예외 처리 설계

### 1. Read Channel 핵심 타이밍 버그 원인 규명 및 완벽 수정 (Key Achievement)

* **🚨 [Troubleshooting] Read Valid-Data 불일치 및 Delta Cycle 캡처 오류 해결**
  * **문제 현상:** Master가 Read Transaction을 수행할 때 기대값(`32'h0000_0004`) 대신 초기 값인 `32'h0000_0000`을 읽어가고, Testbench Task의 `output` 변수(`tb_rdata`)가 `X` (Unknown) 상태 또는 `0`으로 캡처되는 현상 발생.
  * **원인 분석:**
    1. **RTL Valid-Data Mismatch:** FSM 제어 로직상 `s_rvalid` 신호가 먼저 High(`1`)로 올라가고, 정작 실제 데이터 `s_rdata`는 1클럭 뒤늦게 갱신되는 타이밍 어긋남 버그 포착.
    2. **TB Delta Cycle Issue:** Verilog Task의 Copy-out 규칙과 Non-blocking 할당(`<=`) 간의 델타 사이클(Delta Cycle) 시차로 인해, Handshake 시점에 신선한 데이터를 수거하지 못함.
  * **해결 조치:** 조합 회로의 상태 전환 지점(`r_next_state == READ`)을 정밀 타격하여, `s_rvalid`와 `s_rdata`가 동일한 클럭 에지에서 동기식으로 동시에 래치(Latch)되도록 RTL 개편.
  * **검증 결과:** 억지 딜레이(3클럭 지연 등)나 꼼수 구문 없이도 Master가 `s_rvalid = 1`을 감지하는 바로 그 순간 신선한 데이터(`32'h0000_0004`)를 완벽히 수신 성공. 정석 **1-Cycle Read Latency** 타이밍 달성.

### 2. AXI4-Lite RRESP 프로토콜 규격 분석 및 주소 예외 처리 설계

* **RRESP Status Code 스펙 정밀 분석**
  * AXI4-Lite RRESP는 단순 1비트 완료 플래그가 아닌 **2비트 상태 코드** (`2'b00`: OKAY, `2'b10`: SLVERR)임을 재확인.
  * Master는 오직 `s_rvalid = 1`인 핸드셰이크 구간에서만 응답 코드를 평가하므로, IDLE 상태에서 불필요하게 응답 라인을 디폴트 유지할 필요 없이 Valid 펄스와 철저히 동기화 제어.

* **Address Aliasing 감지 및 SLVERR 응답 메커니즘 수립**
  * **주소 경계 체크:** 상위 주소 비트(`buf_araddr[31:4] != 4'b0000`)를 디코딩하여, 정해진 내부 레지스터 범위를 벗어난 비정상 접근을 감지하는 예외 처리 아키텍처 구상.
  * **예외 검증 시나리오:** MSB가 1인 주소 패턴(예: `32'h8000_0000` 등)을 주입했을 때 슬레이브가 이를 범주 외 접근으로 인지하고, B/R 채널 응답으로 `SLVERR (2'b10)` 코드를 정확히 반환하는지 테스트벤치 코너 케이스 시나리오 정립.

---

## 📝 08월 03일: UART-to-AXI Bridge FSM 아키텍처 설계 및 시스템 통합 로드맵 수립

### 1. 시스템 통합 로드맵 및 핵심 모듈 역할 정의

* **UART RX / TX 코어 역할 및 직/병렬 변환 메커니즘**
  * **TX Core (Parallel-to-Serial):** 내부 8비트 병렬 데이터를 표준 보레이트 타임스탬프에 맞춰 1비트 직렬 파형으로 내보내는 발사대.
  * **RX Core (Serial-to-Parallel):** 외부 비동기 1비트 직렬 신호를 16배 오버샘플링하여 신호 정중앙을 정밀 타격, 8비트 병렬 데이터로 복원하는 정밀 센서.
* **Bridge 설계 완료 후 5단계 Full-Chain 검증 로드맵**
  1. **Top-Level 모듈 결합:** `uart_top` + `uart_axi_bridge` + `axi_lite_slave` 최상위 바인딩
  2. **End-to-End System Testbench 시뮬레이션:** PC 입출력 패킷 기반 완전체 시뮬레이션
  3. **Vivado XDC 핀 매핑:** Cmod A7 (Artix-7 XC7A35T) 물리적 IO 및 12MHz/100MHz 클럭 제약 설정
  4. **Synthesis & Bitstream 생성:** Latch 0개, STA Timing Closure (WNS > 0) 달성 및 비트스트림 추출
  5. **FPGA 실물 보드 검증:** PC 시리얼 터미널(Tera Term) ↔ Cmod A7 간 실제 레지스터 Read/Write 릴레이 검증


### 2. UART-to-AXI Bridge 모듈 FSM 구조 및 데이터 패스

* **패킷 프로토콜 및 명령어 디코딩**
  * **Command Decoding:** 수신 첫 바이트의 ASCII 코드를 분석하여 트랜잭션 성격 판단 (`'W'` / `8'h57`: Write, `'R'` / `8'h52`: Read).
  * **`cmd_reg` 선언 필수성:** 주소 및 데이터 바이트가 연속 수신되는 동안 `rx_data` 버스 값이 계속 덮어씌워지므로(Override), 패킷 완결 시점까지 최초 명령어를 보존하기 위한 전용 캡처 레지스터(`cmd_reg`) 배치.
* **3-bit 6-State FSM 아키텍처 수립**
  * `IDLE` ➡️ `RX_ADDR` ➡️ `RX_DATA` / `AXI_WRITE` / `AXI_READ` ➡️ `TX_RESP`
* **Read Data Return Path (수신 데이터 패킷화 반환)**
  * `axi_lite_slave` 읽기 완결 ➡️ Bridge 내부 `rdata_reg` (32-bit) 캡처 ➡️ `TX_RESP` 상태 진입 후 8비트씩 4회 분할하여 UART TX 송신 ➡️ PC 터미널 상에 데이터 최종 출력.


### 3. RTL 설계 및 클럭 타이밍 핵심 포인트

* **`rx_done` 1-Clock Pulse 동기화 및 Concatenation Shift**
  * FPGA 시스템 클럭과 느린 UART 통신 속도 간의 거대한 시차 극복을 위해, 주소 4바이트 수신 중 `rx_done`이 정확히 1클럭 튀어 오르는 상승 에지 시점에만 결합 시프트 연산(`{addr_reg[23:0], rx_data}`) 및 `byte_cnt` 인크리먼트 수행.
* **UART vs AXI 제어 메커니즘 비교**
  * **UART 구간:** 백프레셔(Backpressure)가 없는 단방향 펄스 기반 제어로 간결한 레지스터 갱신 가능.
  * **AXI4-Lite 구간:** 양방향 `VALID`/`READY` 상호 핸드셰이크 유지 및 해제 조건 처리로 인한 세분화된 상태 제어 필요.
* **AXI Deadlock 방지를 위한 Master 주도적 VALID Assertion**
  * AXI 프로토콜 규격에 의거하여 Master(Bridge)는 Slave의 `READY` 응답을 무작정 기다리지 않고, 데이터 준비 완료 즉시 `VALID = 1`을 선제적으로 Assert하여 버스 데드락(Deadlock) 위험을 근본적으로 차단.

---

## 📝 08월 04일: UART-to-AXI Bridge Read Path 4-State FSM 및 2단계 핸드셰이크 제어 로직 정립

### 1. Read Path 중심의 4-State FSM 뼈대 확립

* **Read Transaction 동작을 위한 초간결 4-State FSM 구조**
  * `IDLE`: PC의 명령 패킷('R' / `8'h52` 또는 'W' / `8'h57`) 수신 대기.
  * `RX_ADDR`: PC로부터 4바이트(32-bit) 주소 연속 수신. `rx_done` 펄스를 트리거로 Shift Concatenation 기입.
  * `AXI_READ`: AXI4-Lite Read Protocol 수행 (AR 채널 주소 전달 ➡️ R 채널 데이터 수거).
  * `TX_RESP`: 수신한 32비트 읽기 데이터(`rdata_reg`)를 8비트씩 4회 분할하여 UART TX로 PC 터미널에 반환.


### 2. Sequential vs Combinational 역할 분담 및 Zero-Latency 제어

* **순차 회로 (Sequential Logic: `always @(posedge clk)`)**
  * **대상 변수:** `state`, `ar_done` (AR 완료 플래그), `rdata_reg`, `addr_reg`
  * **설계 목적:** 과거의 이벤트(AR 핸드셰이크 성공 여부)를 레지스터에 기록하고, 수신 데이터를 클럭 에지 동기화로 1클럭 이상 안전하게 보존(Hold)하기 위함.
* **조합 회로 (Combinational Logic: `assign` 출력 버퍼링)**
  * **대상 변수:**
    ```verilog
    assign m_axi_arvalid = (state == AXI_READ) && (!ar_done);
    assign m_axi_rready  = (state == AXI_READ) && (ar_done);
    ```
  * **설계 목적:** FSM이 `AXI_READ` 상태에 진입함과 동시에 1클럭 지연(Latency) 없이 AXI 버스로 `arvalid` / `rready` 신호를 즉시 Assert하기 위함.


### 3. AXI_READ 내부 2단계 순차 핸드셰이크 메커니즘

* **`rx_done` 펄스 역할 제한 및 유령 De-assertion 방지**
  * `rx_done`은 단 1클럭 동안만 High로 튀어 오르는 펄스이므로, **`RX_ADDR` ➡️ `AXI_READ` 상태 전이 트리거**로만 활용.
  * `AXI_READ` 내부의 조합 논리 조건문에 `rx_done`을 직결할 경우, 1클럭 만에 `arvalid`가 0으로 떨어져 AXI 핸드셰이크가 무산되는 치명적 오류 차단.
* **`ar_done` 플래그 기반 2단계 채널 순차 제어**
  * **[1단계 - AR Channel]:** `ar_done == 0`일 때 `arvalid = 1` Assert. AR 핸드셰이크(`m_axi_arvalid && m_axi_arready`) 성사 시 상승 에지에서 `ar_done <= 1` 세팅.
  * **[2단계 - R Channel]:** `ar_done == 1`로 전환되면 `rready = 1` Assert. R 핸드셰이크(`m_axi_rvalid && m_axi_rready`) 성사 시 `s_axi_rdata`를 `rdata_reg`에 안전하게 캡처.
* **`TX_RESP` 탈출 조건 정밀화**
  * R 채널 핸드셰이크(`s_axi_rvalid && m_axi_rready`) 완료 조건 단 하나만을 판단하여, 트랜잭션 수거가 완결된 순간 즉시 `AXI_READ`를 빠져나와 `TX_RESP` 상태로 이탈.
