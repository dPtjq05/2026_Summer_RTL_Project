# 🛠️ 디자인 검증 및 트러블슈팅 아카이브 (Waveform Analysis Log)

> **UART IP 설계 및 통합 과정에서 Vivado 시뮬레이터를 통해 직접 관찰하고 디버깅한 핵심 파형(Waveform) 기록 보관소입니다.**

---

### 📅 [Log #01] 초기 비동기 제어 결함 (Asynchronous Start Glitch)

* **관련 이미지**: <img width="660" height="614" alt="Image" src="https://github.com/user-attachments/assets/bd3538c2-3e6c-4fc9-926d-f23bab73553a" />
* **현상 및 분석**: 처음에 `start` 비트를 주자마자 시스템 클럭이 튀지 않는 상황인데도 `tx` 출력선이 즉각 `0`으로 변하며 비동기적으로 스타트 비트를 뿜어내는 결함 발견. 반면 `tx_busy` 신호는 다음 클럭 상승 에지에서야 활성화되어 두 신호 간 위상 불일치 발생.
* **하드웨어적 깨달음**: 이 구조는 UART 프로토콜 스펙에 어긋나 스타트 비트 유지 시간을 왜곡시키고 글리치(Glitch)에 취약해짐[cite: 2]. 외부 모듈로 나가는 `tx` 출력선은 무조건 시스템 클럭에 완벽히 동기화되어 상태(State)가 변경되는 순간에만 변수 값이 바뀌도록 **Registered Output 구조**로 전면 격리해야 함을 깨달음[cite: 2].

---

### 📅 [Log #02] UART RX 중앙 샘플링(Mid-bit Sampling) 무결성 검증

* **관련 이미지**: <img width="779" height="706" alt="Image" src="https://github.com/user-attachments/assets/bd25ca72-eb93-4c37-ae24-a1225e273711" />
* **현상 및 분석**: `rx` 라인에서 Falling Edge를 검출하여 `START` 상태(State 1)로 진입한 뒤, Baud Rate Generator(BRG)가 뿜어내는 `sampling_tick`을 카운트함[cite: 2]. 
* **검증 결과**: 1비트 셀 폭(16 Ticks)의 정밀한 정중앙인 **7번째 틱이 활성화되는 시점(52.365 μs)**에서 정상적으로 데이터를 샘플링하고, 지체 없이 `DATA` 상태(State 2)로 FSM 상태 천이가 완벽히 동기화되어 이루어짐을 파형 분석으로 최종 증명[cite: 2].

---

### 📅 [Log #03] 제어 신호(tx_busy) 및 상태 천이 동기화 검증

* **관련 이미지**: <img width="519" height="725" alt="Image" src="https://github.com/user-attachments/assets/385545a8-d49b-45d9-a658-f143a5af58ce" />
* **현상 및 분석**: TX 모듈이 내부 상태를 전환하는 핵심 타이밍 마진(**104.525 μs**)을 정밀 분석[cite: 2]. 
* **검증 결과**: 상태 제어선인 `tx_busy` 신호가 외부 노이즈에 비동기적으로 반응하지 않고, 내부 `current_state`가 1에서 2로 천이되는 클럭 에지와 칼같이 동기화되어 하이(`1`)로 활성화됨을 확인하여 출력단의 글리치 차단 성공[cite: 2].

---

### 📅 [Log #04] RX vs TX 모듈 간 상태 전이 위상차(Phase Lag) 분석

* **관련 이미지**: <img width="940" height="751" alt="Image" src="https://github.com/user-attachments/assets/0a6a1611-91f8-465d-a316-2835debbab6d" />
* **현상 및 분석**: 파형 분석 결과, 수신(RX) 모듈보다 송신(TX) 모듈이 상태(State)를 반 박자 늦게 변경하는 위상차 관찰[cite: 2].
* **하드웨어적 깨달음**: RX는 칩 내부에서 노이즈 마진을 확보하기 위해 비트의 정중앙(7번째 틱)만 확인되면 즉시 상태를 넘겨도 되지만, TX는 외부 기기가 안정적으로 읽을 수 있도록 16틱 동안 완벽하게 해당 비트 레벨을 뚝심 있게 유지해 준 뒤에 상태를 변경해야 하기 때문에 발생하는 **UART 프로토콜 고유의 정상적인 위상차**임을 규명[cite: 2].

---

### 📅 [Log #05] 엔드투엔드(End-to-End) 시리얼 비트스트림 및 시프트 동작

* **관련 이미지**: <img width="604" height="695" alt="Image" src="https://github.com/user-attachments/assets/c7e89c41-1276-4b4e-98e9-45ef6b9f2fba" />
* **현상 및 분석**: TX 모듈이 일관적으로 16틱 동안 1비트 신호를 유지하며 방출하는 동안, RX 모듈은 해당 루프백 라인의 중심에서 값을 정확히 가로챔[cite: 2]. 수신된 데이터가 `dout` 레지스터의 상위 비트부터 차근차근 채워지며 우측으로 이동(Shift Right)하는 데이터 경로(Datapath)의 물리적 정밀도 최종 검증[cite: 2].

---

### 📅 [Log #06] 최종 루프백 통합 검증 Pass 및 `rx_done` 플래그 제어

* **관련 이미지**: <img width="940" height="676" alt="Image" src="https://github.com/user-attachments/assets/e3138298-95e3-47cf-9739-369658654cf6" />
* **현상 및 분석**: TX가 16틱 동안 마지막 스톱 비트를 유지하며 외부 출력선에 `1`을 유지시키는 타이밍을 추적[cite: 2].
* **검증 결과**: RX 역시 정확히 해당 타임 슬롯의 중심부에서 스톱 비트를 확인하고 `IDLE` 상태로 복귀함과 동시에, 상위 시스템에 수신 완료를 알리는 **`rx_done` 신호를 정확히 1클럭 동안 활성화**하고 내려오는 청정 펄스 제어 성공[cite: 2]. 최종 버스 출력값 `8'hB2` 매치 확인[cite: 2].

---

### 📅 [Log #07] 룩어헤드(Look-Ahead) 차세대 변수 및 셋업 타임 마진 검증

* **관련 이미지**: <img width="757" height="606" alt="Image" src="https://github.com/user-attachments/assets/f9f5a938-c327-4d37-90ed-f119c9a94049" />
* **현상 및 분석**: `start` 비트가 튀는 저격 타이밍에 조합회로 기반의 차세대 변수들(`next_state`, `next_reg_data`)과 `tx_busy` 신호는 즉각(`1`) 반응하여 길을 열어주고, 실제 저장소 변수들(`current_state`, `current_reg_data`)은 다음 클럭 에지에서 안전하게 값을 넘겨받는 2-Block FSM의 동작 메커니즘 확인[cite: 3].
* **크리티컬 패스 점검**: 메인 카운터(`cnt[9:0]`)와 내부 로컬 카운터(`current_cnt_t`)가 정확히 1클럭의 마진을 두고 순차 전이함을 실증하여, 가산기 회로의 깊이로 인해 발생할 수 있는 **셋업 타임 위반(Setup Time Violation) 리스크를 완벽히 방어**하고 있음을 최종 검증[cite: 3].
