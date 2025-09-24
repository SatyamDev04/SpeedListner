//
//  VerificationViewModel.swift
//  SpeedListners
//
//  Created by Assistant on 9/23/25.
//

import Foundation
import UIKit

/// ViewModel for handling OTP verification and resend flows for VerificationVC1
final class VerificationViewModel {
    // MARK: - Bindings
    /// Called when loading state changes
    var onLoadingChange: ((Bool) -> Void)?
    /// Surface user-visible errors
    var onError: ((String) -> Void)?

    // MARK: - Public API
    /// Verify the provided OTP for an email/phone.
    /// - Parameters:
    ///   - email: The email or phone string used for verification
    ///   - otp: 4-digit OTP
    ///   - onSuccess: Called with the resolved userId on success
    func verifyOTP(email: String, otp: String, onSuccess: @escaping (_ userId: Int) -> Void) {
        let params: [String: Any] = [
            "email": email,
            "otp": otp
        ]

        let url = baseURL.baseURL + appEndPoints.verify_otp
        onLoadingChange?(true)
        WebService.shared.servicePostWithFoamDataParameter(url, params) { [weak self] json, _ in
            guard let self else { return }
            self.onLoadingChange?(false)

            // Convert response to dictionary as current service returns `Any`
            let dictString = "\(json)"
            var dictData: [String: Any]?
            if let data = dictString.data(using: .utf8) {
                do {
                    dictData = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
                } catch {
                    self.onError?(error.localizedDescription)
                    return
                }
            }

            guard let response = dictData else {
                self.onError?("Unexpected response from server.")
                return
            }

            if (response["msg_type"] as? String) == "success" {
                // user_id might come as String in current API
                if let idString = response["user_id"] as? String, let userId = Int(idString) {
                    onSuccess(userId)
                } else if let userId = response["user_id"] as? Int {
                    onSuccess(userId)
                } else {
                    self.onError?("Missing user id in response.")
                }
            } else {
                // Prefer server-provided message if available
                let message = (response["msg"] as? String) ?? "Invalid Code Please Try Again"
                self.onError?(message)
            }
        }
    }

    /// Request a resend of the OTP for the given email.
    /// - Parameters:
    ///   - email: The email/phone to resend to
    ///   - onSuccess: Called when the resend succeeds
    func resendOTP(email: String, onSuccess: @escaping () -> Void) {
        let params: [String: Any] = [
            "email": email
        ]
        let url = baseURL.baseURL + appEndPoints.send_forget_password

        onLoadingChange?(true)
        WebService.shared.servicePostWithFoamDataParameter(url, params) { [weak self] json, _ in
            guard let self else { return }
            self.onLoadingChange?(false)

            let dictString = "\(json)"
            var dictData: [String: Any]?
            if let data = dictString.data(using: .utf8) {
                do {
                    dictData = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
                } catch {
                    self.onError?(error.localizedDescription)
                    return
                }
            }

            guard let response = dictData else {
                self.onError?("Unexpected response from server.")
                return
            }

            if (response["msg_type"] as? String) == "success" {
                onSuccess()
            } else {
                let message = (response["msg"] as? String) ?? "Failed to resend verification code."
                self.onError?(message)
            }
        }
    }
}
