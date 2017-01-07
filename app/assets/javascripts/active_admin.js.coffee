#= require active_admin/base
#= require active_admin/editor

$ ->
  $('#halfday_preset_id').on 'change', ->
    if this.value == '0'
      $('#halfday_place').prop('disabled', false)
      $('#halfday_place').prop('value', '')
      $('#halfday_place_url').prop('disabled', false)
      $('#halfday_place_url').prop('value', '')
      $('#halfday_activity').prop('disabled', false)
      $('#halfday_activity').prop('value', '')
    else
      $('#halfday_place').prop('disabled', true)
      $('#halfday_place').prop('value', 'preset')
      $('#halfday_place_url').prop('disabled', true)
      $('#halfday_place_url').prop('value', 'preset')
      $('#halfday_activity').prop('disabled', true)
      $('#halfday_activity').prop('value', 'preset')
