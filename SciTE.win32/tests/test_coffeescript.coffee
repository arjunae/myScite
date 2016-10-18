initialData = [
    { firstName: "Danny", lastName: "LaRusso", phones: [
        { type: "Mobile", number: "(555) 121-2121" },
        { type: "Home", number: "(555) 123-4567"}]
    },
    { firstName: "Sensei", lastName: "Miyagi", phones: [
        { type: "Mobile", number: "(555) 444-2222" },
        { type: "Home", number: "(555) 999-1212"}]
    }
]

class ContactsModel
    constructor: (contacts) ->
        @contacts = ko.observableArray({
                firstName: contact.firstName
                lastName: contact.lastName
                phones: ko.observableArray(contact.phones)
            } for contact in contacts)

        @addContact = =>
            @contacts.push
                firstName: ""
                lastName: ""
                phones: ko.observableArray()

        @removeContact = (contact) =>
            @contacts.remove(contact)

        @addPhone = (contact) =>
            contact.phones.push
                type: ""
                number: ""

        @removePhone = (phone) =>
            contact.phones.remove phone for contact in @contacts()

        @save = =>
            @lastSavedJson JSON.stringify(ko.toJS(@contacts), null, 2)

        @lastSavedJson = ko.observable ""

$ ->
    ko.applyBindings(new ContactsModel(initialData))