//
//  ExitStateMachine.swift
//  SaveEye
//
//  Created by samzong on 6/16/25.
//

import Carbon
import Combine
import Foundation

class ExitStateMachine: ObservableObject {
    @Published var currentState: ExitState = .idle
    @Published var pressCount: Int = 0
    @Published var showMessage: String = ""

    private var timer: Timer?
    private var cancellables = Set<AnyCancellable>()
    private weak var settings: Settings?

    private let clickWindow: TimeInterval = 2.0
    
    private var delayMinutes: Int {
        return settings?.delayDurationMinutes ?? 5
    }

    enum ExitState {
        case idle
        case firstPress
        case secondPress
        case thirdPress
        case delayRequest
    }

    init(settings: Settings? = nil) {
        self.settings = settings
        setupStateObserver()
    }

    deinit {
        timer?.invalidate()
    }

    func handleEscapePress() {
        switch currentState {
        case .idle:
            enterFirstPress()
        case .firstPress:
            enterSecondPress()
        case .secondPress:
            enterThirdPress()
        case .delayRequest:
            handleDelayEscape()
        case .thirdPress:
            break
        }
    }

    private func enterFirstPress() {
        currentState = .firstPress
        pressCount = 1
        showMessage = L10n.string("exit.press_twice")
        startClickTimer()
    }

    private func enterSecondPress() {
        currentState = .secondPress
        pressCount = 2
        showMessage = L10n.string("exit.press_once")
        restartClickTimer()
    }

    private func enterThirdPress() {
        currentState = .thirdPress
        pressCount = 3
        showMessage = L10n.format("exit.delay_after", L10n.minutes(delayMinutes))

        timer?.invalidate()
        timer = nil

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.triggerDelay()
        }
    }

    private func handleDelayEscape() {
        showMessage = L10n.format("exit.delay_now", L10n.minutes(delayMinutes))

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.triggerDelay()
        }
    }

    private func startClickTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: clickWindow, repeats: false) { [weak self] _ in
            self?.resetToIdle()
        }
    }

    private func restartClickTimer() {
        startClickTimer()
    }

    private func resetToIdle() {
        currentState = .idle
        pressCount = 0
        showMessage = ""
        timer?.invalidate()
        timer = nil
    }

    func enterDelayState() {
        currentState = .delayRequest
        pressCount = 0
        showMessage = L10n.format("exit.ask_delay", L10n.minutes(delayMinutes))

        DispatchQueue.main.asyncAfter(deadline: .now() + 10.0) {
            if self.currentState == .delayRequest {
                self.resetToIdle()
            }
        }
    }

    func forceReset() {
        resetToIdle()
    }

    private func setupStateObserver() {
        $currentState
            .sink { _ in }
            .store(in: &cancellables)
    }



    private func triggerDelay() {
        NotificationCenter.default.post(name: .exitStateMachineDidTriggerDelay, object: nil)
        resetToIdle()
    }

    var stateDescription: String {
        switch currentState {
        case .idle:
            return L10n.string("exit.state.idle")
        case .firstPress:
            return L10n.string("exit.state.first_press")
        case .secondPress:
            return L10n.string("exit.state.second_press")
        case .thirdPress:
            return L10n.string("exit.state.third_press")
        case .delayRequest:
            return L10n.string("exit.state.delay_request")
        }
    }

    var shouldShowMessage: Bool {
        return !showMessage.isEmpty
    }
}

extension Notification.Name {
    static let exitStateMachineDidTriggerDelay = Notification.Name("ExitStateMachineDidTriggerDelay")
}
