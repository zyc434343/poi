{ROOT, layout, _, $, $$, React, ReactBootstrap} = window
{Panel, Table, Label, OverlayTrigger, Tooltip} = ReactBootstrap
{resolveTime} = window
{notify} = window
{join} = require 'path-extra'

timeToString = (dateTime) ->
  if dateTime > 0
    date = new Date(dateTime)
    "#{date.getHours()}:#{date.getMinutes()}:#{date.getSeconds()}"
  else
    ""

CountdownLabel = React.createClass
  getInitialState: ->
    countdown: -1

  updateCountdown: ->
    {countdown} = @state
    if countdown > 0
      countdown = Math.max 0, Math.floor((@props.completeTime - new Date()) / 1000)
      if countdown <= 60 && !@props.notified
        notify "#{@props.deckName} 远征归来",
          type: 'expedition'
          icon: join(ROOT, 'assets', 'img', 'operation', 'expedition.png')
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


MissionPanel = React.createClass
  getInitialState: ->
    decks: [
        name: '第0艦隊'
        completeTime: -1
        mission: null
      ,
        name: '第1艦隊'
        completeTime: -1
        mission: null
      ,
        name: '第2艦隊'
        completeTime: -1
        mission: null
      ,
        name: '第3艦隊'
        completeTime: -1
        mission: null
      ,
        name: '第4艦隊'
        completeTime: -1
        mission: null
    ]
    notified: []
  handleResponse: (e) ->
    {$missions} = window
    {method, path, body, postBody} = e.detail
    switch path
      when '/kcsapi/api_port/port'
        {decks, notified} = @state
        for deck in body.api_deck_port[1..3]
          id = deck.api_id
          switch deck.api_mission[0]
            # In port
            when 0
              completeTime = -1
              notified[id] = false
            # In mission
            when 1
              completeTime = deck.api_mission[2]
            # Just come back
            when 2
              completeTime = 0
          mission_id = deck.api_mission[1]
          if mission_id isnt 0
            mission = $missions[mission_id].api_name
          else
            mission = null
          decks[id] =
            name: deck.api_name
            completeTime: completeTime
            mission: mission
        @setState
          decks: decks
          notified: notified
      when '/kcsapi/api_req_mission/start'
        id = postBody.api_deck_id
        {decks, notified} = @state
        decks[id].completeTime = body.api_complatetime
        mission_id = postBody.api_mission_id
        decks[id].mission = $missions[mission_id].api_name
        notified[id] = false
        @setState
          decks: decks
          notified: notified
      when '/kcsapi/api_req_mission/return_instruction'
        id = postBody.api_deck_id
        {decks, notified} = @state
        decks[id].completeTime = body.api_mission[2]
        @setState
          decks: decks
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
    <Panel header="远征" bsStyle="info">
      <Table>
        <tbody>
        {
          for i in [2..4]
            [
              <tr key={i * 2}>
                <td>{@state.decks[i].name}</td>
                <td>
                  {
                    countdown = Math.max 0, Math.floor((@state.decks[i].completeTime - new Date()) / 1000)
                    if countdown > 60
                      trigger = ['hover', 'focus']
                    else
                      trigger = []
                    <OverlayTrigger trigger={trigger} placement='right' overlay={<Tooltip><strong>归港时间: </strong>{timeToString @state.decks[i].completeTime}</Tooltip>}>
                      <CountdownLabel
                        deckIndex={i}
                        completeTime={@state.decks[i].completeTime}
                        notified={@state.notified}
                        deckName={@state.decks[i].name}
                        setNotifiedHandler={@setNotifiedHandler}/>
                    </OverlayTrigger>
                  }
                </td>
              </tr>,
              <tr key={i * 2 + 1}>
                <td colSpan="2">
                  {
                    if @state.decks[i].mission?
                      <span>↳ {@state.decks[i].mission}</span>
                    else
                      <span>↳</span>
                  }
                </td>
              </tr>
            ]
        }
        </tbody>
      </Table>
    </Panel>

module.exports = MissionPanel
