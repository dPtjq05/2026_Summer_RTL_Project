# 🛠️ 디자인 검증 및 트러블슈팅 아카이브 (Waveform Analysis Log)

> **UART IP 설계 및 통합 과정에서 Vivado 시뮬레이터를 통해 직접 관찰하고 디버깅한 총 10개의 핵심 파형(Waveform) 기록 보관소입니다.**

---

### 📅 [Log #01] 초기 비동기 제어 결함 (Asynchronous Start Bug)

* **관련 이미지 주소**: <img width="660" height="614" alt="Image" src="https://github.com/user-attachments/assets/0b90c283-32f7-475b-9ec5-f0369a828baa" />
* **현상 및 분석**: `start` 신호가 트리거되는 순간 시스템 클럭이 전혀 안 튀는 상황인데도 `tx` 출력선이 즉각 `0`으로 변하며 비동기적으로 스타트 비트를 뿜어내는 결함 발견[cite: 2]. 반면 `tx_busy` 신호는 바로 활성화되지 않고 다음 클럭 상승 에지에서야 튀어 올라 제어 신호 간 위상 불일치 발생[cite: 2].
* **하드웨어적 리스크**: 이 구조는 UART 프로토콜 스펙에 어긋나 스타트 비트 유지 시간을 왜곡시키고 글리치(Glitch)에 취약해짐[cite: 2].

---

### 📅 [Log #02] 비동기 결함 수정 및 출력단 동기화 확인 (Registered Output Resolution)

* **관련 이미지 주소**: <img width="779" height="706" alt="Image" src="https://github.com/user-attachments/assets/8914839f-7dc9-4d80-9985-711c7466570c" />
* **현상 및 분석**: Log #01의 비동기 문제를 해결하기 위해 상태(State)가 변경되는 순간에만 변수의 값이 클럭에 동기화되어 바뀔 수 있도록 제어 회로 전면 수정[cite: 2]. 
* **검증 결과**: 출력 신호 제어선을 상태 천이 흐름과 완전히 일치시키고 플립플롭 레지스터 구조를 강제 적용하여, 클럭 오동작 구간에서도 안정적인 파형 마진을 확보하는 데 성공[cite: 2].

---

### 📅 [Log #03] UART RX 수신기 중앙 샘플링(Mid-bit Sampling) 무결성 검증

* **관련 이미지 주소**: <img width="519" height="725" alt="Image" src="https://github.com/user-attachments/assets/5650e58f-e777-42e8-af9c-e867fc7f68e5" />
* **현상 및 분석**: `rx` 라인에서 Falling Edge를 검출하여 `START` 상태(State 1)로 진입한 뒤, Baud Rate Generator(BRG)가 뿜어내는 `sampling_tick`을 카운트함[cite: 2]. 
* **검증 결과**: 1비트 셀 폭(16 Ticks)의 정밀한 정중앙인 **7번째 틱이 활성화되는 시점(52.365 μs)**에서 정확하게 `rx` 신호의 한가운데를 읽어갔음을 확인[cite: 2]. 지체 없이 `DATA` 상태(State 2)로 FSM 상태 천이가 완벽히 동기화되어 이루어짐을 최종 증명[cite: 2].

---

### 📅 [Log #04] 제어 신호(tx_busy) 및 상태 천이 동기화 검증

* **관련 이미지 주소**: <img width="940" height="751" alt="Image" src="https://github.com/user-attachments/assets/bca91a45-112e-41d7-82cc-86bd988a78c5" />
* **현상 및 분석**: TX 모듈이 내부 상태를 전환하는 핵심 타이밍 마진(**104.525 μs**)을 정밀 분석[cite: 2]. 
* **검증 결과**: 상태 제어선인 `tx_busy` 신호가 외부 입력에 비동기적으로 반응하지 않고, 내부 `current_state`가 1에서 2로 천이되는 시점과 칼같이 동기화되어 하이(`1`)로 활성화됨을 확인하여 출력단의 글리치 차단 성공[cite: 2].

---

### 📅 [Log #05] RX vs TX 모듈 간 상태 전이 위상차(Phase Lag) 원인 분석

* **관련 이미지 주소**: <img width="604" height="695" alt="Image" src="https://github.com/user-attachments/assets/bb9e51c4-5e4c-4ea5-a6ec-9d528a3155c2" />
* **현상 및 분석**: 파형 분석 결과, 수신(RX) 모듈보다 송신(TX) 모듈이 상태(State)를 반 박자 늦게 변경하는 위상차 관찰[cite: 2].
* **하드웨어적 깨달음**: RX는 칩 내부에서 노이즈 마진을 확보하기 위해 비트의 정중앙(7번째 틱)만 확인되면 즉시 상태를 넘겨도 되지만, TX는 외부 기기가 안정적으로 읽을 수 있도록 16틱 동안 완벽하게 해당 비트 레벨을 유지해 준 뒤에 상태를 변경해야 하기 때문에 발생하는 **UART 프로토콜 고유의 정상적인 위상차**임을 규명[cite: 2].

---

### 📅 [Log #06] 16-Tick 비트 폭 유지 및 RX 우측 시프트(Shift Right) 연산 검증

* **관련 이미지 주소**: <img width="940" height="676" alt="Image" src="https://github.com/user-attachments/assets/fd93de24-303b-46ba-a87b-bfc8b9b0045d" />
* **현상 및 분석**: TX 모듈이 일관적으로 16틱 동안 1비트 신호를 유지하며 방출하는 동안, RX 모듈은 해당 루프백 라인의 중심에서 값을 가로챔[cite: 2]. 
* **검증 결과**: 수신된 데이터가 `dout` 레지스터의 상위 비트부터 차근차근 채워지며 우측으로 이동(Shift Right)하는 데이터 경로(Datapath)의 물리적 정밀도 최종 검증[cite: 2].

---

### 📅 [Log #07] 최종 루프백 통합 검증 Pass 및 수신 완료(`rx_done`) 플래그 제어

* **관련 이미지 주소**: <img width="757" height="606" alt="Image" src="https://github.com/user-attachments/assets/6878a1ae-f0f1-4a31-a36d-b8e3a48cc57b" />
* **현상 및 분석**: TX가 16틱 동안 마지막 스톱 비트를 유지하며 외부 출력선에 `1`을 유지시키는 타이밍을 추적[cite: 2].
* **검증 결과**: RX 역시 정확히 해당 타임 슬롯의 중심부에서 스톱 비트를 확인하고 `IDLE` 상태로 복귀함과 동시에, 상위 시스템에 수신 완료를 알리는 **`rx_done` 신호를 정확히 하이(1)로 올리는 플래그 펄스 제어 성공**을 최종 파형 분석으로 증명[cite: 2].

---

### 📅 [Log #08] 2-Block FSM 룩어헤드(Look-Ahead) 차세대 변수 동작 실증

* **관련 이미지 주소**: <img width="901" height="734" alt="Image" src="https://github.com/user-attachments/assets/b2f4c4d4-31ee-40e4-b448-31f405a66636" />
* **현상 및 분석**: `start` 비트가 튀는 타이밍에 조합회로 기반의 차세대 변수들과 제어 신호들의 상태 변화 관찰[cite: 3].
* **검증 결과**: `start`가 인가되는 즉시 1) `tx_busy`는 딜레이 없이 바로 1로 변경되고, 2) `reg_data` 및 상태의 `next_state` 차세대 조합회로 변수들이 실시간으로 선행 변경됨을 확인[cite: 3]. 이후 3) 도래하는 다음 클럭 에지에서 `current_state` 변수에 안전하게 값이 동기화되어 안착하는 2-Block FSM의 우수한 동작 제어력 증명[cite: 3].

---

### 📅 [Log #09] 1클럭 주기 타이밍 플래그 및 로컬 카운터 동기화 추적

* **관련 이미지 주소**: <img width="940" height="500" alt="Image" src="https://github.com/user-attachments/assets/a798d817-1372-4beb-ac39-1dfb86fb53f8" />
* **현상 및 분석**: 내부 메인 분주 카운터와 로컬 카운터의 타이밍 동기화 여부 정밀 관찰[cite: 3].
* **검증 결과**: `sampling_tick`이 정확히 1클럭 주기 동안만 정상적으로 튀어 오르는 것을 확인[cite: 3]. 이와 연동된 내부 FSM 카운터 값인 `count_t`(`current_cnt_t` / `next_cnt_t`) 역시 정확히 1클럭의 마진 차이를 유지하며 동기식 플립플롭으로 안전하게 전이되고 있음을 파형 상에서 증명[cite: 3].

---

### 📅 [Log #10] 1➡️2 상태 천이 구간 셋업 타임(Setup Time) 의심 및 LSB 출력 규명

* **관련 이미지 주소**: <img width="940" height="689" alt="Image" src="https://github.com/user-attachments/assets/f519c534-aaa8-4b39-9b21-9e551c7a1abb" />
* **현상 및 분석**: 1에서 2로 상태가 넘어가는 과정에서 셋업 타임을 확보하지 못해 `tx` 출력선으로 데이터가 깨져서 전달되는 듯한 가짜 타이밍 버그 의심 상황 발생[cite: 3].
* **오해 해결 및 결론**: 파형을 세부 확대하여 데이터 경로를 정밀 역추적한 결과, UART 표준 프로토콜 규격에 따라 데이터의 **LSB(최하위 비트)부터 순서대로 정상 출력**해 주고 있기 때문에 위상이 밀려 보였던 것일 뿐, 실제로는 하드웨어 데이터 유실 없이 무결하게 값이 전달되고 있음을 최종 확정[cite: 3].

---

### 📅 [Log #11] UART-to-AXI Bridge End-to-End AXI Write 파형 검증 (9.326ms 타임스탬프)
* **관련 이미지 주소**: <img width="861" height="443" alt="Image" src="https://github.com/user-attachments/assets/0f55e414-950f-4f35-9d3f-1d003e2cfcd4" />
* **현상 및 분석**: Testbench에서 인가한 9바이트 패킷(ASCII `'W'` + 4-byte Address + 4-byte Write Data)이 `uart_top`을 거쳐 Bridge 모듈에 차곡차곡 수신되는 전체 데이터패스 추적. $9.326\text{ms}$ 타임스탬프 지점에서 9바이트 수신 완결 직후 AXI Write 트랜잭션으로 성공적으로 진입하는 파형 모니터링.
* **검증 결과**: `awaddr = 32'h0000_0010`, `wdata = 32'h0000_0110` 신호가 AXI 버스로 유실 없이 래칭되고, Slave와의 `VALID`/`READY` 상호 핸드셰이크가 정밀하게 완결됨을 확인하여 Full-Chain 동작 최종 증명.

---

### 📅 [Log #12] UART RX Midpoint Sampling 및 rx_done 동기식 1클럭 펄스 검증
* **관련 이미지 주소**: <img width="803" height="403" alt="image" src="https://github.com/user-attachments/assets/0071be6b-be9a-44d8-8118-048e14b6a3f3" />
* **현상 및 분석**: Baud Rate Generator 타임스탬프 기준 비트 정중앙(Midpoint)에서 데이터 샘플링 시 `rx_data = 8'h57` ('W')으로 확정되는 시점 분석. Stop Bit 정중앙 감지 직후 `rx_done` 신호의 토글 동작 포착.
* **검증 결과**: `rx_done` 신호가 정확히 1 시스템 클럭 주기(Single-cycle Pulse) 동안만 Assert됨을 확인. `rx_done == 1` 트리거 시점에 `cmd_reg <= 8'h57` 래칭 완료 후, 다음 클럭 상승 에지(`posedge clk`)에서 `current_state`가 0에서 1로 에러 없이 정상 천이됨을 최종 입증.

---

### 📅 [Log #13] Big-Endian 32-bit Shift Concatenation 수신 파형 검증
* **관련 이미지 주소**:<img width="940" height="347" alt="image" src="https://github.com/user-attachments/assets/2cd2e2cc-6b56-40cc-9678-4e025738c234" />
* **현상 및 분석**: 32비트 주소 및 데이터 수신 과정에서 `cnt_data` 카운터 변화와 `data_reg` 버스 값의 갱신 타임라인 정밀 모니터링 (`32'h1001_0010` 인가 시나리오).
* **검증 결과**: 수신되는 바이트 스트림이 상위 바이트(MSB)부터 하위 바이트(LSB) 순서(`10` ➔ `01` ➔ `00` ➔ `10`)로 차곡차곡 시프트 결합(`{data_reg[23:0], rx_data}`)되는 Big-Endian 수신 방식을 파형 상에서 증명. 주소 수신(State 2) 및 데이터 수신(State 3)으로의 연속 FSM 천이 완료.

---

### 📅 [Log #14] AXI Write Transaction 디버깅 및 Handshake De-assertion 파형 검증
* **관련 이미지 주소**:<img width="728" height="321" alt="image" src="https://github.com/user-attachments/assets/7bcead4c-5513-48f1-b826-493ff192e3ea" />
* **현상 및 분석**: AXI Write 수행 시 발생했던 Red X (`32'hXXXX_XXXX`) 래칭, `bresp` Floating (`Z`) 및 FSM State 0 ↔ 3 무한 토글 현상의 원인을 파형 상의 클럭 에지 단위로 역추적.
* **오해 해결 및 결론**: Bus Data 사전 Settlement 조치로 Setup Time 시차에 의한 Red X 래칭을 상쇄하였으며, `s_axi_bresp = 2'b00` (OKAY) 명시적 할당 및 핸드셰이크 직후 `s_awvalid`/`s_wvalid`를 즉시 De-assert 하도록 수정하여 1-Shot 법칙 준수 및 FSM 정상 복귀 파형 최종 확정.

---

### 🚨 [Issue 15] Bridge ↔ UART TX 간 `tx_busy` 조합 피드백 루프(Combinational Loop)로 인한 시뮬레이션 Hang
* **문제 현상**: 시뮬레이션 실행 시 특정 타임스탬프에서 무한 조합 루프(Combinational Loop)에 빠지며 시뮬레이터가 응답 없음(Hang) 상태로 정지함.
* **관련 이미지 주소**:<img width="940" height="494" alt="image" src="https://github.com/user-attachments/assets/e1808d03-347d-4dea-8dac-cc2df3e9d707" />
* **원인 분석**: Bridge 모듈과 UART TX 모듈 사이에서 `tx_busy` 신호가 조합 논리(`always @(*)`) 연산 경로를 타고 피드백 고리를 형성하여 무한 데드락 피드백 발생.
* **해결 아키텍처**: `tx_busy` 신호를 `always @(posedge clk)` 순차 논리(Flip-Flop)로 감싸 래칭함으로써 모듈 간 조합 논리 피드백 고리를 완벽히 끊어냄.
* **💡 하드웨어적 깨달음:** 모듈 간 교차 제어 핸드셰이크 신호는 반드시 순차 회로(D-FF)로 가두어 Combinational Cloud 피드백 루프를 차단해야 시스템 안정성이 보장됨.

### 🚨 [Issue 16] 순차 제어로 인한 1-Clock Pipeline Lag 및 STOP 비트 경계 침범 버그
* **문제 현상**: `tx` 직렬 출력선을 순차 논리로 제어 시 1클럭 지연(Pipeline Lag)이 발생하여 데이터 비트 위상이 밀리고, STOP 비트 구간을 침범하는 버그 발생.
* **관련 이미지 주소**:<img width="756" height="481" alt="image" src="https://github.com/user-attachments/assets/085df41d-b781-4b37-8529-4e60554f756b" />
* **원인 분석**: `state` 및 `cnt_d` 카운터 변경 시점 대비 `tx` 출력 레지스터가 1클럭 뒤늦게 갱신되는 순차 회로 Latency 특성 때문임.
* **해결 아키텍처**: 상태/카운터 제어는 순차 회로(FF)로 유지하되, 최상위 `tx` 출력 신호만 조합 논리 MUX(`always @(*)` 또는 `assign`)로 분리하여 `state`와 `cnt_d` 변화에 0ps(Zero-Latency)로 즉각 반응하도록 하이브리드 최적화.
* **💡 하드웨어적 깨달음**: RTL 설계 시 단일 방식을 고집하기보다 "플립플롭 제어(안정성) + 조합 MUX 출력(Zero Latency)"을 결합하는 것이 타이밍 마진 사수의 정석임.

### 🚨 [Issue 17] Bridge Write FSM 응답 패킷 분기 오류 및 AXI Slave `dummy_reg` 쓰기 불능 현상
* **문제 현상**: Write 트랜잭션 후 PC로 1바이트 ACK 대신 Read용 5바이트 페이로드가 출력을 시도하며, AXI Slave 내부 `dummy_reg`에 값이 기입되지 않는 현상 발생.
* **관련 이미지 주소**:<img width="940" height="500" alt="image" src="https://github.com/user-attachments/assets/615fad50-3cbf-4e3a-9897-d7e326ecd508" />
* **원인 분석**: Bridge FSM 내 Write 완료 루틴 분기 조건 오작동 및 AXI Slave 쓰기 채널(`WVALID & WREADY`), `WSTRB` 인가 시점 불일치 추정.
* **해결 아키텍처**: (진행 중) Bridge FSM 응답 루틴 분기 조건 수정 및 AXI Write 핸드셰이크, 주소 디코딩, `WSTRB` 타이밍 정밀 디버깅 진행 중.
* **💡 하드웨어적 깨달음**: AXI Master-Slave 프로토콜 통신 시 Write ACK와 Read Payload 간의 FSM 상태 분기를 엄격히 제어하지 않으면 통신 프로토콜 꼬임 현상이 발생함.
