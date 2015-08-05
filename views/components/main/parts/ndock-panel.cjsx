{ROOT, layout, _, $, $$, React, ReactBootstrap} = window
{resolveTime} = window
{Panel, Table, Label, OverlayTrigger, Tooltip} = ReactBootstrap
{join} = require 'path-extra'

timeToString = (dateTime) ->
  date = new Date(dateTime)
  "#{date.getHours()}:#{date.getMinutes()}:#{date.getSeconds()}"

CountdownLabel = React.createClass
  getInitialState: ->
    countdown: -1

  updateCountdown: ->
    {countdown} = @state
    if countdown > 0
      countdown = Math.max 0, Math.floor((@props.completeTime - new Date()) / 1000)
      if countdown <= 60 && !@props.notified
        notify "#{docks[i].name} 修复完成",
          type: 'repair'
          icon: join(ROOT, 'assets', 'img', 'operation', 'repair.png')
        @props.setNotifiedHandler @props.deckIndex, true
      else
        @setState
          countdown: countdown
  componentDidMount: ->
    setInterval @updateCountdown, 1000
  componentWillUnmount: ->
    clearInterval @updateCountdown, 1000
  componentWillMount: ->
    if @props.completeTime >= 0
      countdown = Math.max 0, Math.floor((@props.completeTime - new Date()) / 1000)
      @setState
        countdown: countdown
    else
      @setState
        countdown: -1
  componentWillReceiveProps: (nextProps)->
    if nextProps.completeTime >= 0
      countdown = Math.max 0, Math.floor((nextProps.completeTime - new Date()) / 1000)
      @setState
        countdown: countdown
    else
      @setState
        countdown: -1
  render: ->
    <div>
      {
        if @state.countdown > 60
          <Label bsStyle="primary">{resolveTime @state.countdown}</Label>
        else if @state.countdown >= 0
          <Label bsStyle="success">{resolveTime @state.countdown}</Label>
        else
          <Label bsStyle="default"></Label>
      }
    </div>

NdockPanel = React.createClass
  getInitialState: ->
    docks: [
        name: '未使用'
        completeTime: -1
      ,
        name: '未使用'
        completeTime: -1
      ,
        name: '未使用'
        completeTime: -1
      ,
        name: '未使用'
        completeTime: -1
      ,
        name: '未使用'
        completeTime: -1
    ]
    notified: []
  handleResponse: (e) ->
    {method, path, body, postBody} = e.detail
    {$ships, _ships} = window
    {docks, notified} = @state
    switch path
      when '/kcsapi/api_port/port'
        for ndock in body.api_ndock
          id = ndock.api_id
          switch ndock.api_state
            when -1
              docks[id] =
                name: '未解锁'
                completeTime: -1
            when 0
              docks[id] =
                name: '未使用'
                completeTime: -1
              notified[id] = false
            when 1
              docks[id] =
                name: $ships[_ships[ndock.api_ship_id].api_ship_id].api_name
                completeTime: ndock.api_complete_time
        @setState
          docks: docks
          notified: notified
      when '/kcsapi/api_get_member/ndock'
        for ndock in body
          id = ndock.api_id
          switch ndock.api_state
            when -1
              docks[id] =
                name: '未解锁'
                completeTime: -1
            when 0
              docks[id] =
                name: '未使用'
                completeTime: -1
              notified[id] = false
            when 1
              docks[id] =
                name: $ships[_ships[ndock.api_ship_id].api_ship_id].api_name
                completeTime: ndock.api_complete_time
        @setState
          docks: docks
          notified: notified
  setNotifiedHandler: (i, value)->
    {notified} = @state
    notified[i] = value
    @setState
      notified: notified
  componentDidMount: ->
    window.addEventListener 'game.response', @handleResponse
  componentWillUnmount: ->
    window.removeEventListener 'game.response', @handleResponse
  render: ->
    <Panel header="入渠" bsStyle="warning">
      <Table>
        <tbody>
        {
          for i in [1..4]
            <tr key={i}>
              <td>{@state.docks[i].name}</td>
              <td>
                {
                  countdown = Math.max 0, Math.floor((@state.docks[i].completeTime - new Date()) / 1000)
                  if countdown > 60
                    trigger = ['hover', 'focus']
                  else
                    trigger = []
                  <OverlayTrigger trigger={trigger} placement='right' overlay={<Tooltip><strong>完成时间: </strong>{timeToString @state.docks[i].completeTime}</Tooltip>}>
                    <div>
                      <CountdownLabel
                        dockIndex={i}
                        completeTime={@state.docks[i].completeTime}
                        notified={@state.notified}
                        dockName={@state.docks[i].name}
                        setNotifiedHandler={@setNotifiedHandler} />
                    </div>
                  </OverlayTrigger>
                }
              </td>
            </tr>
        }
        </tbody>
      </Table>
    </Panel>

module.exports = NdockPanel
