import SwiftUI

struct AccountView: View {
    @Environment(AuthStore.self) private var auth
    @Environment(RewardsStore.self) private var rewards

    var body: some View {
        NavigationStack {
            Group {
                if auth.isSignedIn {
                    SignedInAccountView()
                } else {
                    AccountAuthView()
                }
            }
            .background(Theme.background.ignoresSafeArea())
            .toolbar(auth.isSignedIn ? .visible : .hidden, for: .navigationBar)
            .navigationTitle("Account")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

private struct AccountAuthView: View {
    @Environment(AuthStore.self) private var auth
    @Environment(RewardsStore.self) private var rewards

    @State private var mode: AuthMode = .signIn
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var isSubmitting = false
    @State private var errorMessage: String?

    enum AuthMode {
        case signIn
        case signUp
    }

    var body: some View {
        BrandActionCard {
            VStack(spacing: 12) {
                VStack(spacing: 6) {
                    authField {
                        TextField("Email", text: $email)
                            .keyboardType(.emailAddress)
                            .textContentType(.username)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                    }

                    authField {
                        SecureField("Password", text: $password)
                            .textContentType(mode == .signUp ? .newPassword : .password)
                    }

                    Group {
                        if mode == .signUp {
                            authField {
                                SecureField("Confirm password", text: $confirmPassword)
                                    .textContentType(.newPassword)
                            }
                        } else {
                            Color.clear
                                .accessibilityHidden(true)
                        }
                    }
                    .frame(height: Theme.authFieldHeight)

                    Text(errorMessage ?? " ")
                        .font(.caption2)
                        .foregroundStyle(errorMessage == nil ? .clear : .red)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .frame(height: 14)

                    Button {
                        if mode == .signIn {
                            mode = .signUp
                        } else {
                            mode = .signIn
                            confirmPassword = ""
                        }
                        errorMessage = nil
                    } label: {
                        Text(mode == .signIn ? "Don't have an account? Sign up" : "Already have an account? Sign in")
                            .font(.caption)
                            .foregroundStyle(Theme.primary)
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.plain)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)

                Button {
                    Task { await submit() }
                } label: {
                    Text(submitTitle)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.primaryAction(isEnabled: canSubmit && !isSubmitting))
            }
            .frame(maxWidth: Theme.buttonMaxWidth, maxHeight: .infinity, alignment: .top)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
    }

    private func authField<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        content()
            .font(.subheadline)
            .frame(maxWidth: .infinity, minHeight: 22, alignment: .leading)
            .padding(.horizontal, 10)
            .frame(height: Theme.authFieldHeight)
            .background(Theme.background.opacity(0.6))
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }

    private var submitTitle: String {
        if isSubmitting {
            return mode == .signIn ? "Signing in…" : "Creating account…"
        }
        return mode == .signIn ? "Sign in" : "Create account"
    }

    private var canSubmit: Bool {
        guard FirestoreRewardsUserWriter.isValidEmail(email), password.count >= 6 else { return false }
        if mode == .signUp {
            return password == confirmPassword
        }
        return true
    }

    private func submit() async {
        isSubmitting = true
        errorMessage = nil
        defer { isSubmitting = false }

        if mode == .signUp, password != confirmPassword {
            errorMessage = "Passwords do not match."
            return
        }

        do {
            if mode == .signIn {
                try await auth.signIn(email: email, password: password)
            } else {
                try await auth.signUp(email: email, password: password)
            }
            guard let userID = auth.userID, let userEmail = auth.userEmail else { return }
            try await rewards.restoreSession(userID: userID, email: userEmail)
            email = ""
            password = ""
            confirmPassword = ""
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

private struct SignedInAccountView: View {
    @Environment(AuthStore.self) private var auth
    @Environment(RewardsStore.self) private var rewards

    @State private var firstName = ""
    @State private var lastName = ""
    @State private var phone = ""
    @State private var birthday: Date?
    @State private var marketingOptIn = false
    @State private var isSaving = false
    @State private var errorMessage: String?
    @State private var showSaved = false

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            Form {
                Section("Account") {
                    if let email = auth.userEmail {
                        LabeledContent("Email") {
                            Text(email)
                                .font(.caption.monospaced())
                        }
                    }
                }

                Section("Profile") {
                    TextField("First name", text: $firstName)
                        .textContentType(.givenName)

                    TextField("Last name", text: $lastName)
                        .textContentType(.familyName)

                    TextField("Phone", text: $phone)
                        .keyboardType(.phonePad)
                        .textContentType(.telephoneNumber)
                        .onChange(of: phone) { _, newValue in
                            let formatted = PhoneNumberFormatter.format(newValue)
                            if formatted != newValue {
                                phone = formatted
                            }
                        }

                    HStack {
                        Text("Birthday")
                        Spacer()
                        if birthday != nil {
                            DatePicker(
                                "",
                                selection: Binding(
                                    get: { birthday ?? Date() },
                                    set: { birthday = $0 }
                                ),
                                in: ...Date(),
                                displayedComponents: .date
                            )
                            .labelsHidden()

                            Button {
                                birthday = nil
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundStyle(Theme.mutedText)
                            }
                            .buttonStyle(.plain)
                        } else {
                            Button("Optional") {
                                birthday = Calendar.current.date(
                                    from: DateComponents(year: 2000, month: 1, day: 1)
                                )
                            }
                            .font(.body)
                            .foregroundStyle(Theme.mutedText)
                        }
                    }
                }

                Section("Preferences") {
                    Toggle("Send me offers & updates", isOn: $marketingOptIn)
                }

                Section {
                    Button("Sign out", role: .destructive) {
                        signOut()
                    }
                }

                if let errorMessage {
                    Section {
                        Text(errorMessage)
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                }

                if let syncError = rewards.lastSyncError {
                    Section {
                        Text(syncError)
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .safeAreaInset(edge: .bottom) {
                Color.clear.frame(height: 72)
            }

            Button {
                Task { await save() }
            } label: {
                Group {
                    if isSaving {
                        ProgressView()
                            .tint(Theme.onPrimary)
                    } else {
                        Image(systemName: "checkmark")
                            .font(.title3.weight(.semibold))
                            .foregroundStyle(Theme.onPrimary)
                    }
                }
                .frame(width: 56, height: 56)
                .background(Theme.primary)
                .clipShape(Circle())
                .shadow(color: Theme.primary.opacity(0.28), radius: 10, y: 4)
            }
            .disabled(isSaving)
            .accessibilityLabel("Save profile")
            .padding(.trailing, 20)
            .padding(.bottom, 20)
        }
        .onAppear { loadFromStore() }
        .onChange(of: auth.userEmail) { _, _ in
            loadFromStore()
        }
        .alert("Profile saved", isPresented: $showSaved) {
            Button("OK", role: .cancel) {}
        }
    }

    private func loadFromStore() {
        firstName = rewards.account.firstName
        lastName = rewards.account.lastName
        phone = PhoneNumberFormatter.format(rewards.account.phone)
        marketingOptIn = rewards.account.marketingOptIn
        birthday = rewards.account.birthday
    }

    private func save() async {
        guard let email = auth.userEmail else { return }

        isSaving = true
        errorMessage = nil
        defer { isSaving = false }

        do {
            try await rewards.saveProfile(
                firstName: firstName,
                lastName: lastName,
                phone: phone,
                birthday: birthday,
                marketingOptIn: marketingOptIn,
                authenticatedEmail: email
            )
            showSaved = true
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func signOut() {
        do {
            try auth.signOut()
            rewards.signOut()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

#Preview {
    AccountView()
        .environment(AuthStore())
        .environment(RewardsStore())
}
