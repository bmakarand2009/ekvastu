import Foundation
import Combine

// MARK: - Global Tenant Configuration Manager
@MainActor
class TenantConfigManager: ObservableObject {
    static let shared = TenantConfigManager()
    
    // MARK: - Published Properties
    @Published var tenantConfig: TenantPingResponse?
    @Published var signInTenant: Tenant?
    @Published var isConfigLoaded = false
    
    // MARK: - Computed Properties for Easy Access
    var tenantName: String {
        return tenantConfig?.name ?? APIConfig.tenantName
    }
    
    var tenantId: String {
        return tenantConfig?.tenantId ?? ""
    }
    
    var cloudinaryCloudName: String {
        // Priority: SignIn tenant config > Ping config > Config.plist fallback
        if let signInCloudName = signInTenant?.cloudinaryCloudName, !signInCloudName.isEmpty {
            return signInCloudName
        }
        if let pingCloudName = tenantConfig?.cloudName, !pingCloudName.isEmpty {
            return pingCloudName
        }
        return ConfigManager.cloudinaryCloudName
    }
    
    var cloudinaryUploadPreset: String {
        // Priority: SignIn tenant config > hardcoded fallback
        if let preset = signInTenant?.cloudinaryPreset, !preset.isEmpty {
            return preset
        }
        return "qjdp0fft" // Updated fallback preset to ml_default which is commonly available
    }
    
    var cloudinaryFolder: String {
        let folder = tenantName
        print("🗂️ TenantConfigManager: cloudinaryFolder = '\(folder)'")
        print("   - tenantConfig?.name: \(tenantConfig?.name ?? "nil")")
        print("   - APIConfig.tenantName: \(APIConfig.tenantName)")
        return folder
    }
    
    // MARK: - Private Init
    private init() {}
    
    // MARK: - Configuration Methods
    func updateTenantConfig(_ config: TenantPingResponse) {
        print("🏢 TenantConfigManager: Updating tenant config")
        print("   - Tenant Name: \(config.name)")
        print("   - Tenant ID: \(config.tenantId)")
        print("   - Cloud Name: \(config.cloudName)")
        
        self.tenantConfig = config
        self.isConfigLoaded = true
    }
    
    func updateSignInTenant(_ tenant: Tenant) {
        print("🔐 TenantConfigManager: Updating signin tenant config")
        print("   - Tenant Name: \(tenant.name)")
        print("   - Cloudinary Cloud Name: \(tenant.cloudinaryCloudName ?? "N/A")")
        print("   - Cloudinary Preset: \(tenant.cloudinaryPreset ?? "N/A")")
        
        self.signInTenant = tenant
    }
    
    func clearConfig() {
        print("🧹 TenantConfigManager: Clearing tenant config")
        self.tenantConfig = nil
        self.signInTenant = nil
        self.isConfigLoaded = false
    }
    
    // MARK: - Debug Info
    func printCurrentConfig() {
        print("📋 TenantConfigManager Current Config:")
        print("   - Tenant Name: \(tenantName)")
        print("   - Tenant ID: \(tenantId)")
        print("   - Cloudinary Cloud Name: \(cloudinaryCloudName)")
        print("   - Cloudinary Upload Preset: \(cloudinaryUploadPreset)")
        print("   - Cloudinary Folder: \(cloudinaryFolder)")
        print("   - Config Loaded: \(isConfigLoaded)")
    }
}
