# 2026_Summer_RTL_Project

# 🛰️ UART to Register Map Controller IP Design

> **FPGA (Artix-7 / Cmod A7) 환경에서 12MHz 시스템 클럭을 기반으로 동작하는 고신뢰성 UART IP 및 레지스터 맵 제어기 설계 프로젝트입니다.**

---

## 📅 5-Day Agile Roadmap

방학 전반기 동안 완벽한 하드웨어 IP 설계를 목표로 진행하는 5일간의 점진적 개발 로드맵입니다.

| 일정 | 단계 | 핵심 개발 및 검증 내용 | 상태 |
| :---: | :---: | :--- | :---: |
| **Day 1** | **환경 구축 & 분석** | Git/Vivado 디렉터리 정형화, `.gitignore` 최적화, 보레이트 분주 법칙 분석 | **완료 (Done)** |
| **Day 2** | **Baud Rate Gen** | 16배수 오버샘플링 클럭 분주기 설계 및 Testbench 시뮬레이션 검증 | 진행 예정 |
| **Day 3** | **UART RX** | 시작 비트 오버샘플링 검증 및 FSM 기반 수신기 설계 | 대기 |
| **Day 4** | **UART TX** | 프레임 빌더 기반 송신기 설계 및 Loopback 통합 시뮬레이션 | 대기 |
| **Day 5** | **Register Map** | 주소 디코더 및 레지스터 읽기/쓰기 버스 인터페이스 통합 검증 | 대기 |

---

## 📝 Day 1: 연구 및 인프라 설계 내용

### 1. 개발 환경 최적화 (Clean Directory Structure)

Vivado가 무분별하게 생성하는 임시 파일들로 인해 원격 저장소가 오염되는 것을 방지하기 위해, 소스 코드와 프로젝트 설정을 완전히 분리하는 실무 표준 구조를 도입했습니다.

* **`src/`**: 직접 설계하는 순수 Verilog 하드웨어 소스 코드
* **`tb/`**: 시뮬레이션 검증용 고기능 테스트벤치 소스 코드
* **`vivado_prj/`**: 비바도 도구 전용 작업 공간 (`.gitignore` 설정을 통해 임시 파일 추적 차단)

### 2. Baud Rate Generator (클럭 분주기) 사양 정의

* **시스템 입력 클럭 ($f_{\text{clk}}$):** $12\text{ MHz}$
* **목표 보레이트 (Baud Rate):** $9,600\text{ bps}$
* **오버샘플링 배수:** $16\text{x}$ (노이즈 필터링 및 안정적인 비트 센터 저격을 위함)
* **목표 틱 주파수 ($f_{\text{tick}}$):** $9,600 \times 16 = 153,600\text{ Hz}$
* **카운터 분주비 (Division Ratio):**
  $$12,000,000\text{ Hz} \div 153,600\text{ Hz} = 78.125 \approx 78$$

* **분주기 동작 사양:**
  * 오차율 $0.15\%$ 미만의 고신뢰성 분주 계수 **`78`** 도출.
  * $0$부터 $77$까지 카운팅하기 위해 최소 **7비트 레지스터**(`reg [6:0]`) 설계 사양 확정.

---

## 🚀 시작하기 (How to Run)

### 1. 전제 조건

* Vivado Design Suite (2020.1 이상 권장)
* Cmod A7-35T Target Board

### 2. 프로젝트 로드 및 시뮬레이션

1. 본 레포지토리를 클론합니다.
   ```bash
   git clone [https://github.com/dPtjq05/2026_Summer_RTL_Project.git](https://github.com/dPtjq05/2026_Summer_RTL_Project.git)