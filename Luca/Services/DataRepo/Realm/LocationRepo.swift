import Foundation
import RealmSwift

class LocationRealmModel: RealmSaveModel<Location> {
    
    @objc dynamic var locationId: String = ""
    @objc dynamic var publicKey: String = ""
    @objc dynamic var radius: Double = 0.0
    @objc dynamic var name: String? = nil
    @objc dynamic var locationName: String? = nil
    @objc dynamic var groupName: String? = nil
    @objc dynamic var firstName: String? = nil
    @objc dynamic var lastName: String? = nil
    @objc dynamic var phone: String? = nil
    @objc dynamic var streetName: String? = nil
    @objc dynamic var streetNr: String? = nil
    @objc dynamic var zipCode: String? = nil
    @objc dynamic var city: String? = nil
    @objc dynamic var state: String? = nil
    
    var lat = RealmOptional<Double>()
    var lng = RealmOptional<Double>()
    var startsAt = RealmOptional<Int>()
    var endsAt = RealmOptional<Int>()

    override func create() -> Location {
        return Location(locationId: "", publicKey: "", radius: 0)
    }

    override func populate(from: Location) {
        super.populate(from: from)
        
        locationId = from.locationId
        publicKey = from.publicKey
        radius = from.radius
        name = from.name
        locationName = from.locationName
        groupName = from.groupName
        firstName = from.firstName
        lastName = from.lastName
        phone = from.phone
        streetName = from.streetName
        streetNr = from.streetNr
        zipCode = from.zipCode
        city = from.city
        state = from.state
        
        lat.value = from.lat
        lng.value = from.lng
        startsAt.value = from.startsAt
        endsAt.value = from.endsAt
    }

    override var model: Location {
        var m = super.model
        
        m.locationId = locationId
        m.publicKey = publicKey
        m.radius = radius
        m.name = name
        m.groupName = groupName
        m.locationName = locationName
        m.firstName = firstName
        m.lastName = lastName
        m.phone = phone
        m.streetName = streetName
        m.streetNr = streetNr
        m.zipCode = zipCode
        m.city = city
        m.state = state
        
        m.lat = lat.value
        m.lng = lng.value
        m.startsAt = startsAt.value
        m.endsAt = endsAt.value
        return m
    }
}

class LocationRepo: RealmDataRepo<LocationRealmModel, Location> {
    override func createSaveModel() -> LocationRealmModel {
        return LocationRealmModel()
    }
    
    init() {
        super.init(schemaVersion: 0, customFilename: "LocationRepo")
    }
}
