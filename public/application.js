$.ajaxSetup({
  'beforeSend': function(xhr) { xhr.setRequestHeader("Accept", "text/javascript")}
})

$(function(){
  $('form').submit(function(){
    $(this).find('button').attr('disabled', true);
    $('form div.url').html('Combinificating...');
    $.post($(this).attr('action'), $(this).serialize(), function(resp){
      var data = resp.split('|');
      var li   = $("<li>");
      var a    = $("<a>").attr('href', data[1]).appendTo(li);
      var img  = $("<img />").attr('src', data[2]).attr('width', '200').attr('height', '200').appendTo(a);
      $('ul.images').prepend(li);
      $('form div.url').html($("<a>").attr('href', data[0]).text(data[0]));
      $('form button').attr('disabled', false);
    });
    return false;
  });
});
