###
generated by base-domain generator
###

Entity = require('base-domain').Entity

###*
entity class of <%= @model  %>


@class <%= @Model %>

@extends Entity
###
class <%=@Model%> extends Entity

    ###*
    property types
    key:   property name
    value: type

    @property properties
    @static
    @protected
    @type Object
    ###
    @properties:
        name      : @TYPES.STRING
    ### examples
        age         : @TYPES.NUMBER
        confirmed   : @TYPES.BOOLEAN
        confirmedAt : @TYPES.DATE
        team        : @TYPES.MODEL 'team'
        hobbies     : @TYPES.MODELS 'hobby'
        createdAt   : @TYPES.CREATED_AT
        updatedAt   : @TYPES.UPDATED_AT
    ###

module.exports = <%=@Model %>
