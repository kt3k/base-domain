###
generated by base-domain generator
###


BaseRepository = require('base-domain').BaseRepository

###*
repository of <%= @model  %>


@class <%= @Model %>Repository
@extends BaseRepository
###
class <%=@Model %>Repository extends BaseRepository

    ###*
    model name to create

    @property modelName
    @static
    @protected
    @type String
    ###
    @modelName: '<%=@model %>'

module.exports = <%=@Model %>Repository