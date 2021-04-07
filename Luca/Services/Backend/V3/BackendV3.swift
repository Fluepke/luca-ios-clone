import Foundation
import Alamofire

class BackendAddressV3: BackendAddress {
    
    #if DEBUG
    var host: URL { URL(string: "https://staging.luca-app.de")! }
    #else
    var host: URL { URL(string: "https://app.luca-app.de")! }
    #endif
    
    #if DEBUG
    var apiUrl: URL { URL(string: "https://staging.luca-app.de/api/v3")! }
    #else
    var apiUrl: URL { URL(string: "https://app.luca-app.de/api/v3")! }
    #endif
}

class DefaultBackendDailyKeyV3: BackendDailyKeyV3 {
    
    private let backendAddress: BackendAddressV3
    
    init(backendAddress: BackendAddressV3) {
        self.backendAddress = backendAddress
    }
    
    func retrieveDailyPubKey() -> AsyncDataOperation<BackendError<RetrieveDailyKeyError>, PublicKeyFetchResultV3> {
        RetrieveDailyKeyAsyncOperationV3(backendAddress: backendAddress)
    }
    
    func retrieveIssuerKeys(issuerId: String) -> AsyncDataOperation<BackendError<RetrieveDailyKeyError>, IssuerKeysFetchResultV3> {
        RetrieveIssuerKeysAsyncOperationV3(backendAddress: backendAddress, issuerId: issuerId)
    }
}

class BackendSMSVerificationV3: BaseBackendSMSVerification {
    
    init(backendAddress: BackendAddressV3) {
        super.init(backendAddress: backendAddress)
    }
}

class BackendUserV3: BackendUserV3Protocol {
    
    private let backendAddress: BackendAddressV3
    private let userDataBuilder: UserDataPackageBuilderV3
    private let userTransferBuilder: UserTransferBuilderV3
    
    init(backendAddress: BackendAddressV3, userDataBuilder: UserDataPackageBuilderV3, userTransferBuilder: UserTransferBuilderV3) {
        self.backendAddress = backendAddress
        self.userDataBuilder = userDataBuilder
        self.userTransferBuilder = userTransferBuilder
    }
    
    func create(userData: UserRegistrationData) -> AsyncDataOperation<BackendError<CreateUserError>, UUID> {
        CreateUserAsyncOperationV3(backendAddress: backendAddress, builder: userDataBuilder, data: userData)
    }
    
    func userExists(userId: UUID) -> AsyncOperation<BackendError<UserExistsError>> {
        UserExistsCheckRequestAsyncOperationV3(backendAddress: backendAddress, userId: userId)
    }
    
    func update(userId: UUID, userData: UserRegistrationData) -> AsyncOperation<BackendError<UpdateUserError>> {
        UpdateUserAsyncOperationV3(backendAddress: backendAddress, builder: userDataBuilder, data: userData, userId: userId)
    }
    
    func userTransfer(userId: UUID) -> AsyncDataOperation<BackendError<UserTransferError>, String> {
        UserTransferAsyncOperationV3(backendAddress: backendAddress, userTransferBuilder: userTransferBuilder, userId: userId)
    }
}

class BackendTraceIdV3: BackendTraceIdV3Protocol {
    
    private let backendAddress: BackendAddressV3
    private let checkInBuilder: CheckInPayloadBuilderV3
    private let checkOutBuilder: CheckOutPayloadBuilderV3
    private let additionalDataBuilder: TraceIdAdditionalDataBuilderV3
    
    init(backendAddress: BackendAddressV3,
         checkInBuilder: CheckInPayloadBuilderV3,
         checkOutBuilder: CheckOutPayloadBuilderV3,
         additionalDataBuilder: TraceIdAdditionalDataBuilderV3) {
        self.backendAddress = backendAddress
        self.checkInBuilder = checkInBuilder
        self.checkOutBuilder = checkOutBuilder
        self.additionalDataBuilder = additionalDataBuilder
    }
    
    func checkIn(qrCode: QRCodePayloadV3, venuePubKey: KeySource, scannerId: String) -> AsyncOperation<BackendError<CheckInError>> {
        CheckInAsyncOperationV3(
            backendAddress: backendAddress,
            checkInBuilder: checkInBuilder,
            qrCodePayload: qrCode,
            venuePubKey: venuePubKey,
            scannerId: scannerId)
    }
    
    func fetchInfo(traceId: TraceId) -> AsyncDataOperation<BackendError<FetchTraceInfoError>, TraceInfo> {
        FetchTraceInfoRequestAsyncOperation(backendAddress: backendAddress, traceId: traceId)
    }
    
    func fetchInfo(traceIds: [TraceId]) -> AsyncDataOperation<BackendError<FetchTraceInfoError>, [TraceInfo]> {
        FetchTraceInfosRequestAsyncOperation(backendAddress: backendAddress, traceIds: traceIds)
    }
    
    func checkOut(traceId: TraceId, timestamp: Date) -> AsyncOperation<BackendError<CheckOutError>> {
        CheckOutAsyncOperationV3(backendAddress: backendAddress, checkOutBuilder: checkOutBuilder, traceId: traceId, timestamp: timestamp)
    }
    
    func updateAdditionalData<T>(traceId: TraceId, scannerId: String, venuePubKey: KeySource, additionalData: T) -> AsyncOperation<BackendError<UploadAdditionalDataError>> where T: Encodable {
        
        UploadAdditionalDataRequestAsyncOperationV3(
            backendAddress: backendAddress,
            additionalDataBuilder: additionalDataBuilder,
            traceId: traceId,
            scannerId: scannerId,
            venuePubKey: venuePubKey,
            additionalData: additionalData)
    }
}

class BackendLocationV3: BackendLocation {
    
    private let backendAddress: BackendAddressV3
    
    init(backendAddress: BackendAddressV3) {
        self.backendAddress = backendAddress
    }
    
    func fetchLocation(locationId: UUID) -> AsyncDataOperation<BackendError<FetchLocationError>, Location> {
        FetchLocationAsyncOperation(backendAddress: backendAddress, locationId: locationId)
    }
    
    func createPrivateMeeting(publicKey: SecKey) -> AsyncDataOperation<BackendError<CreatePrivateMeetingError>, PrivateMeetingIds> {
        CreatePrivateMeetingAsyncOperation(backendAddress: backendAddress, publicKey: publicKey)
    }
    
    func fetchLocationGuests(accessId: String) -> AsyncDataOperation<BackendError<FetchLocationGuestsError>, [PrivateMeetingGuest]> {
        FetchGuestListAsyncOperation(backendAddress: backendAddress, accessId: accessId)
    }
    
    func deletePrivateMeeting(accessId: String) -> AsyncOperation<BackendError<DeletePrivateMeetingError>> {
        DeletePrivateMeetingAsyncOperation(backendAddress: backendAddress, accessId: accessId)
    }
}

class BackendMiscV3: CommonBackendMisc {
    
    init(backendAddress: BackendAddressV3) {
        super.init(backendAddress: backendAddress)
    }
}