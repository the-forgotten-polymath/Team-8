// CompleteProfileView.swift
import SwiftUI

public struct CompleteProfileView: View {
    @StateObject private var viewModel: CompleteProfileViewModel
    @State private var showConfirmDialog = false
    @State private var showNewPassword = false
    @State private var showConfirmPassword = false
    
    public init(authViewModel: AuthViewModel) {
        _viewModel = StateObject(wrappedValue: CompleteProfileViewModel(authViewModel: authViewModel))
    }
    
    public var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    
                    Image(systemName: "person.crop.circle.badge.exclamationmark")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 80, height: 80)
                        .foregroundColor(.blue)
                        .padding(.top, 40)
                    
                    Text("Complete Your Profile")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text("For security reasons, you must change your temporary username and password before accessing the application.")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)
                    
                    VStack(alignment: .leading, spacing: 16) {
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Current Profile")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            TextField("", text: .constant(viewModel.currentUsername))
                                .disabled(true)
                                .padding()
                                .background(Color(.systemGray6))
                                .cornerRadius(10)
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("New Username")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            TextField("Enter new username", text: $viewModel.newUsername)
                                .autocapitalization(.none)
                                .disableAutocorrection(true)
                                .padding()
                                .background(Color(.systemGray6))
                                .cornerRadius(10)
                            
                            if !viewModel.newUsername.isEmpty && !viewModel.isValidUsername {
                                Text("Min 4, max 30 chars. No spaces.")
                                    .font(.caption)
                                    .foregroundColor(.red)
                            }
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("New Password")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            HStack {
                                if showNewPassword {
                                    TextField("Enter new password", text: $viewModel.newPassword)
                                } else {
                                    SecureField("Enter new password", text: $viewModel.newPassword)
                                }
                                Button(action: { showNewPassword.toggle() }) {
                                    Image(systemName: showNewPassword ? "eye.slash" : "eye")
                                        .foregroundColor(.gray)
                                }
                            }
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(10)
                            
                            if !viewModel.newPassword.isEmpty && !viewModel.isValidPassword {
                                Text("Min 8 chars, 1 uppercase, 1 lowercase, 1 number.")
                                    .font(.caption)
                                    .foregroundColor(.red)
                            }
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Confirm Password")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            HStack {
                                if showConfirmPassword {
                                    TextField("Confirm new password", text: $viewModel.confirmPassword)
                                } else {
                                    SecureField("Confirm new password", text: $viewModel.confirmPassword)
                                }
                                Button(action: { showConfirmPassword.toggle() }) {
                                    Image(systemName: showConfirmPassword ? "eye.slash" : "eye")
                                        .foregroundColor(.gray)
                                }
                            }
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(10)
                            
                            if !viewModel.confirmPassword.isEmpty && !viewModel.passwordsMatch {
                                Text("Passwords do not match.")
                                    .font(.caption)
                                    .foregroundColor(.red)
                            }
                        }
                        
                    }
                    .padding(.horizontal, 24)
                    
                    if let errorMessage = viewModel.errorMessage {
                        Text(errorMessage)
                            .font(.callout)
                            .foregroundColor(.red)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    
                    Button(action: {
                        showConfirmDialog = true
                    }) {
                        HStack {
                            Spacer()
                            if viewModel.isSaving {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                Text("Save & Continue")
                                    .font(.headline)
                                    .foregroundColor(.white)
                            }
                            Spacer()
                        }
                        .frame(height: 54)
                        .background(viewModel.canSave && !viewModel.isSaving ? Color.blue : Color.gray)
                        .cornerRadius(12)
                    }
                    .disabled(!viewModel.canSave || viewModel.isSaving)
                    .padding(.horizontal, 24)
                    .padding(.bottom, 40)
                    
                    Spacer()
                }
            }
            .background(Color(UIColor.systemBackground).edgesIgnoringSafeArea(.all))
            .navigationBarHidden(true)
            .alert("Confirm Credentials", isPresented: $showConfirmDialog) {
                Button("Cancel", role: .cancel) { }
                Button("Confirm", role: .destructive) {
                    Task {
                        _ = await viewModel.save()
                    }
                }
            } message: {
                Text("You are about to replace your temporary login credentials. These new credentials will be used for all future logins.")
            }
        }
    }
}
