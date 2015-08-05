{ROOT, layout, _, $, $$, React, ReactBootstrap} = window
{resolveTime, success, warn} = window
{Panel, Table, OverlayTrigger, Tooltip, Label} = ReactBootstrap
{join} = require 'path-extra'

getMaterialImage = (idx) ->
  return "#{ROOT}/assets/img/material/0#{idx}.png"

CountdownLabel = React.createClass
  getInitialState: ->
    countdown: -1
  updateCountdown: ->
    {countdown} = @state
    if countdown > 0
      countdown = Math.max 0, Math.floor((@props.completeTime - new Date()) / 1000)
      if countdown <= 1 && !@props.notified
        notify "#{@props.dockName} 建造完成",
          type: 'construction'
          icon: join(ROOT, 'assets', 'img', 'operation', 'build.png')
        @props.setNotifiedHandler @props.dockIndex, true
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
    <td>
      {
        if @state.countdown > 0
          if @props.material[0] >= 1000
            <Label bsStyle="danger">{resolveTime @state.countdown}</Label>
          else
            <Label bsStyle="primary">{resolveTime @state.countdown}</Label>
        else if @state.countdown is 0
          <Label bsStyle="success">{resolveTime @state.countdown}</Label>
        else
          <Label bsStyle="default"></Label>
      }
    </td>
    

KdockPanel = React.createClass
  getInitialState: ->
    docks: [
        name: '未使用'
        material: []
        completeTime: -1
      ,
        name: '未使用'
        material: []
        completeTime: -1
      ,
        name: '未使用'
        material: []
        completeTime: -1
      ,
        name: '未使用'
        material: []
        completeTime: -1
      ,
        name: '未使用'
        material: []
        completeTime: -1
    ]
    notified: []
  handleResponse: (e) ->
    {method, path, body, postBody} = e.detail
    {$ships} = window
    {docks, notified} = @state
    switch path
      when '/kcsapi/api_get_member/kdock'
        for kdock in body
          id = kdock.api_id
          switch kdock.api_state
            when -1
              docks[id] =
                name: '未解锁'
                material: []
                completeTime: -1
            when 0
              docks[id] =
                name: '未使用'
                material: []
                completeTime: -1
              notified[id] = false
            when 2
              docks[id] =
                name: $ships[kdock.api_created_ship_id].api_name
                material: [
                  kdock.api_item1
                  kdock.api_item2
                  kdock.api_item3
                  kdock.api_item4
                  kdock.api_item5
                ]
                completeTime: kdock.api_complete_time
            when 3
              docks[id] =
                name: $ships[kdock.api_created_ship_id].api_name
                material: [
                  kdock.api_item1
                  kdock.api_item2
                  kdock.api_item3
                  kdock.api_item4
                  kdock.api_item5
                ]
                completeTime: 0
        @setState
          docks: docks
          notified: notified
      when '/kcsapi/api_req_kousyou/getship'
        for kdock in body.api_kdock
          id = kdock.api_id
          switch kdock.api_state
            when -1
              docks[id] =
                name: '未解锁'
                material: []
                completeTime: -1
            when 0
              docks[id] =
                name: '未使用'
                material: []
                completeTime: -1
              notified[id] = false
            when 2
              docks[id] =
                name: $ships[kdock.api_created_ship_id].api_name
                material: [
                  kdock.api_item1
                  kdock.api_item2
                  kdock.api_item3
                  kdock.api_item4
                  kdock.api_item5
                ]
                completeTime: kdock.api_complete_time
            when 3
              docks[id] =
                name: $ships[kdock.api_created_ship_id].api_name
                material: [
                  kdock.api_item1
                  kdock.api_item2
                  kdock.api_item3
                  kdock.api_item4
                  kdock.api_item5
                ]
                completeTime: 0
        @setState
          docks: docks
          notified: notified
      when '/kcsapi/api_req_kousyou/createitem'
        if body.api_create_flag == 0
          setTimeout warn.bind(@, "#{$slotitems[parseInt(body.api_fdata.split(',')[1])].api_name} 开发失败"), 500
        else if body.api_create_flag == 1
          setTimeout success.bind(@, "#{$slotitems[body.api_slot_item.api_slotitem_id].api_name} 开发成功"), 500
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
    <Panel header="建造" bsStyle="danger">
      <Table>
        <tbody>
        {
          for i in [1..4]
            <tr key={i}>
              <OverlayTrigger placement='left' overlay={
                  <Tooltip>
                    <img src={getMaterialImage 1} className="material-icon" /> {@state.docks[i].material[0]} <img src={getMaterialImage 3} className="material-icon" /> {@state.docks[i].material[2]}<br />
                    <img src={getMaterialImage 2} className="material-icon" /> {@state.docks[i].material[1]} <img src={getMaterialImage 4} className="material-icon" /> {@state.docks[i].material[3]}<br />
                    <img src={getMaterialImage 7} className="material-icon" /> {@state.docks[i].material[4]}
                  </Tooltip>
                }>
                {
                  if @state.docks[i].material[0] >= 1500 && @state.docks[i].material[1] >= 1500 && @state.docks[i].material[2] >= 2000 || @state.docks[i].material[3] >= 1000
                    <td><strong style={color: '#d9534f'}>{@state.docks[i].name}</strong></td>
                  else
                    <td>{@state.docks[i].name}</td>
                }
              </OverlayTrigger>
              <CountdownLabel
                key={i}
                dockIndex={i}
                material={@state.docks[i].material}
                completeTime={@state.docks[i].completeTime}
                notified={@state.notified[i]}
                dockName={@state.docks[i].name}
                setNotifiedHandler={@setNotifiedHandler}/>
            </tr>
        }
        </tbody>
      </Table>
    </Panel>

module.exports = KdockPanel
