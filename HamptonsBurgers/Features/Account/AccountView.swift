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
    @State private var appeared = false

    enum AuthMode {
        case signIn
        case signUp
    }

    var body: some View {
        GeometryReader { geo in
            let metrics = AccountAuthLayoutMetrics(size: geo.size)

            ZStack {
                atmosphere

                VStack(spacing: 0) {
                    Spacer(minLength: metrics.edgeBreathingRoom)

                    authCard(logoSize: metrics.logoSize)
                        .frame(maxWidth: metrics.contentWidth)
                        .opacity(appeared ? 1 : 0)
                        .offset(y: appeared ? 0 : 10)

                    Spacer(minLength: metrics.edgeBreathingRoom)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(.horizontal, metrics.horizontalPadding)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.9)) {
                appeared = true
            }
        }
    }

    private var atmosphere: some View {
        LinearGradient(
            colors: [
                Theme.background,
                Theme.secondary.opacity(0.07),
                Theme.background
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }

    private func authCard(logoSize: CGFloat) -> some View {
        VStack(spacing: 20) {
            VStack(spacing: 14) {
                Image("Logo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: logoSize, height: logoSize)
                    .accessibilityLabel("\(BrandConfig.appName) logo")

                Text(BrandConfig.orderTaglines.joined(separator: " · "))
                    .font(.caption2.weight(.semibold))
                    .tracking(0.6)
                    .textCase(.uppercase)
                    .foregroundStyle(Theme.text.opacity(0.62))
                    .multilineTextAlignment(.center)
                    .lineLimit(1)
                    .minimumScaleFactor(0.65)
                    .allowsTightening(true)
                    .padding(.horizontal, 2)
            }

            VStack(alignment: .leading, spacing: 10) {
                Text(mode == .signIn ? "Sign in" : "Create account")
                    .font(.caption.weight(.bold))
                    .tracking(1.0)
                    .textCase(.uppercase)
                    .foregroundStyle(Theme.mutedText)
                    .frame(maxWidth: .infinity, alignment: .leading)

                VStack(spacing: 8) {
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

                    // Always reserve this row so sign-in / sign-up cards stay the same height.
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
                    .frame(height: 44)
                }

                VStack(spacing: 6) {
                    Text(errorMessage ?? " ")
                        .font(.caption2)
                        .foregroundStyle(errorMessage == nil ? .clear : Color(hex: "C44B3C"))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .frame(height: 12, alignment: .center)
                        .lineLimit(1)
                        .minimumScaleFactor(0.85)

                    Button {
                        Task { await submit() }
                    } label: {
                        Text(submitTitle)
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.primaryAction(isEnabled: canSubmit && !isSubmitting, fillsWidth: true))
                }

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
                        .font(.caption.weight(.medium))
                        .foregroundStyle(Theme.primary)
                        .frame(maxWidth: .infinity)
                        .frame(height: 18)
                        .lineLimit(1)
                        .minimumScaleFactor(0.85)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 22)
        .padding(.bottom, 20)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Theme.surface)
                .shadow(color: Theme.primary.opacity(0.05), radius: 10, y: 3)
        )
    }

    private func authField<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        content()
            .font(.subheadline)
            .foregroundStyle(Theme.text)
            .frame(maxWidth: .infinity, minHeight: 22, alignment: .leading)
            .padding(.horizontal, 12)
            .frame(height: 44)
            .background(Theme.background.opacity(0.72))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
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

private struct AccountAuthLayoutMetrics {
    let size: CGSize

    var horizontalPadding: CGFloat {
        size.width < 360 ? 20 : 24
    }

    var contentWidth: CGFloat {
        min(360, size.width - (horizontalPadding * 2))
    }

    /// Match Order tab logo sizing. Slightly reduced on short phones so card + form fit.
    var logoSize: CGFloat {
        if size.height < 700 {
            return 128
        }
        if size.height < 780 {
            return 148
        }
        if size.height < 900 {
            return 168
        }
        return 180
    }

    var edgeBreathingRoom: CGFloat {
        size.height < 700 ? 16 : 24
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
