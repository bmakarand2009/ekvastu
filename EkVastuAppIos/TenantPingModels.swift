import Foundation

// MARK: - Tenant Ping Response Model
struct TenantPingResponse: Codable {
    let c: Int
    let address: Address
    let bigLogo: String
    let buyButtonLabel: String
    let cloudName: String
    let country: String
    let csymbol: String
    let customDomain: String?
    let email: String
    let environmentName: String
    let isEnableCourses: Bool
    let isMasterFranchise: Bool
    let isMultiCountrySupport: Bool
    let isShowCalenderView: Bool
    let isShowCourses: Bool
    let isShowDonation: Bool
    let isShowOnlineZoomMeeting: Bool
    let isShowRegistrationLink: Bool
    let isShowRoomName: Bool
    let isShowSchedule: Bool
    let isShowScheduleMenu: Bool
    let isShowSidebar: Bool
    let isShowStoreMenu: Bool
    let isShowWorkshops: Bool
    let isSupportGrn: Bool
    let isTermsAgreed: Bool
    let isWaiverFormToBeSigned: Bool
    let logo: String
    let masterOrgId: String
    let name: String
    let notificationOnesignalAppId: String?
    let orgGuId: String
    let orgId: String
    let phone: String
    let privacyPolicyLink: String?
    let promotionLabel: String
    let registerButtonLabel: String
    let registrationLinkName: String
    let scheduleLabel: String
    let smallLogo: String
    let tenantAuthViewCmd: TenantAuthViewCmd
    let tenantId: String
    let termsOfServiceLink: String?
    let timezone: String
    let version: String
    let waiverFormLink: String
    let workshopLabel: String
    let web: [WebItem]
    let socials: [Social]
    let org: Organization
    let forms: [Form]
    
    struct Address: Codable {
        let line1: String
        let line2: String
    }
    
    struct TenantAuthViewCmd: Codable {
        let clientId: String
        let domain: String
    }
    
    struct WebItem: Codable {
        let name: String
        let title: String
        let url: String
        let externalLink: String
        let isExternalLink: Bool
        let header: String?
        let subHeader: String?
        let footer: String?
        let isLegal: Bool
        let sequence: Int
        let isShowNavigation: Bool
        let isShowFooter: Bool
    }
    
    struct Social: Codable {
        let name: String
        let value: String
    }
    
    struct Organization: Codable {
        let logo: String
        let logoWidth: Int
        let logoHeight: Int
        let isScaleLogo: Bool?
        let favIcon: String
        let headerColor: String
        let pageScript: String
        let title: String
        let seoDescription: String
        let googleId: String
        let isShowFooter: Bool
        let footerInfo: String
        let tosLink: String?
        let privacyPolicyLink: String?
        let favIconUrl: String?
        
        private enum CodingKeys: String, CodingKey {
            case logo, logoWidth, logoHeight, isScaleLogo, favIcon, headerColor, pageScript, title, seoDescription, googleId, isShowFooter, footerInfo, tosLink, privacyPolicyLink, favIconUrl
        }
        
        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            logo = try container.decodeIfPresent(String.self, forKey: .logo) ?? ""
            logoWidth = try container.decodeIfPresent(Int.self, forKey: .logoWidth) ?? 0
            logoHeight = try container.decodeIfPresent(Int.self, forKey: .logoHeight) ?? 0
            isScaleLogo = try container.decodeIfPresent(Bool.self, forKey: .isScaleLogo)
            favIcon = try container.decodeIfPresent(String.self, forKey: .favIcon) ?? ""
            headerColor = try container.decodeIfPresent(String.self, forKey: .headerColor) ?? ""
            pageScript = try container.decodeIfPresent(String.self, forKey: .pageScript) ?? ""
            title = try container.decodeIfPresent(String.self, forKey: .title) ?? ""
            seoDescription = try container.decodeIfPresent(String.self, forKey: .seoDescription) ?? ""
            googleId = try container.decodeIfPresent(String.self, forKey: .googleId) ?? ""
            isShowFooter = try container.decodeIfPresent(Bool.self, forKey: .isShowFooter) ?? false
            footerInfo = try container.decodeIfPresent(String.self, forKey: .footerInfo) ?? ""
            tosLink = try container.decodeIfPresent(String.self, forKey: .tosLink)
            privacyPolicyLink = try container.decodeIfPresent(String.self, forKey: .privacyPolicyLink)
            favIconUrl = try container.decodeIfPresent(String.self, forKey: .favIconUrl)
        }
    }
    
    struct Form: Codable {
        let afterForm: FormContent?
        let beforeForm: FormContent?
        let customFields: [CustomFieldWrapper]?
        let customFormName: String?
        let date: Int
        let formType: String?
        let guId: String
        let header: String?
        let isCustomForm: Bool
        let isEmail: Bool?
        let isMasterForm: Bool?
        let isName: Bool?
        let isPhone: Bool?
        let isPublishToStudent: Bool
        let isShowAddress: Bool
        let isShowBirthdate: Bool
        let isShowEmergencyContact: Bool
        let isShowOnWebsite: Bool
        let isSignRequired: Bool
        let name: String
        let subHeader: FormContent?
        let tid: String
        let type: String
        
        private enum CodingKeys: String, CodingKey {
            case afterForm, beforeForm, customFields, customFormName, date, formType, guId, header, isCustomForm, isEmail, isMasterForm, isName, isPhone, isPublishToStudent, isShowAddress, isShowBirthdate, isShowEmergencyContact, isShowOnWebsite, isSignRequired, name, subHeader, tid, type
        }
        
        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            afterForm = try container.decodeIfPresent(FormContent.self, forKey: .afterForm)
            beforeForm = try container.decodeIfPresent(FormContent.self, forKey: .beforeForm)
            customFields = try container.decodeIfPresent([CustomFieldWrapper].self, forKey: .customFields)
            customFormName = try container.decodeIfPresent(String.self, forKey: .customFormName)
            date = try container.decode(Int.self, forKey: .date)
            formType = try container.decodeIfPresent(String.self, forKey: .formType)
            guId = try container.decode(String.self, forKey: .guId)
            header = try container.decodeIfPresent(String.self, forKey: .header)
            isCustomForm = try container.decode(Bool.self, forKey: .isCustomForm)
            isEmail = try container.decodeIfPresent(Bool.self, forKey: .isEmail)
            isMasterForm = try container.decodeIfPresent(Bool.self, forKey: .isMasterForm)
            isName = try container.decodeIfPresent(Bool.self, forKey: .isName) ?? true
            isPhone = try container.decodeIfPresent(Bool.self, forKey: .isPhone)
            isPublishToStudent = try container.decode(Bool.self, forKey: .isPublishToStudent)
            isShowAddress = try container.decode(Bool.self, forKey: .isShowAddress)
            isShowBirthdate = try container.decode(Bool.self, forKey: .isShowBirthdate)
            isShowEmergencyContact = try container.decode(Bool.self, forKey: .isShowEmergencyContact)
            isShowOnWebsite = try container.decode(Bool.self, forKey: .isShowOnWebsite)
            isSignRequired = try container.decode(Bool.self, forKey: .isSignRequired)
            name = try container.decode(String.self, forKey: .name)
            subHeader = try container.decodeIfPresent(FormContent.self, forKey: .subHeader)
            tid = try container.decode(String.self, forKey: .tid)
            type = try container.decode(String.self, forKey: .type)
        }
        
        struct FormContent: Codable {
            let description: String
            let guId: String
        }
        
        struct CustomFieldWrapper: Codable {
            let sequence: Int
            let customField: CustomField
        }
        
        struct CustomField: Codable {
            let customForm: String?
            let fieldName: String?
            let guId: String
            let isDisabled: Bool
            let isFormField: Bool
            let isListOnWebsite: Bool
            let isMandatory: Bool
            let name: String
            let option1: String?
            let option2: String?
            let option3: String?
            let option4: String?
            let option5: String?
            let option6: String?
            let placeholder: String?
            let sequence: Int
            let tag: String?
            let type: String
        }
    }
}
