//
//  UserRepository.swift
//  MimiSupply
//
//  Created by Kiro on 13.08.25.
//

import Foundation

/// User repository protocol for managing user data
protocol UserRepository: Sendable {
    func saveUser(_ user: UserProfile) async throws
    func fetchUser(by appleUserID: String) async throws -> UserProfile?
    func fetchCurrentUser() async throws -> UserProfile?
    func updateUser(_ user: UserProfile) async throws
    func deleteUser(_ userId: String) async throws
}