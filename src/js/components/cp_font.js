'use strict';


import _ from '../toolbox/gettext';
import WebFont from 'webfontloader';

/**
 * load a font to render the codepoint figure
 */
export default function load_font($cp) {
  var cp_fig = $('figure .fig', $cp);
  if (cp_fig.length) {
    var font_opts = $('#fonts option');
    if (font_opts.length) {
      var cp_font = font_opts.eq(0).val(),
          cp_fam  = $.trim(font_opts.eq(0).text());
      if (cp_font) {
        var block_id = $cp.data('blockId');
        WebFont.load({
          custom: {
            families: [cp_font],
            urls: ['/api/font-face/blocks/'+encodeURIComponent(block_id)+'.css']
          },
          active: function() {
            cp_fig.css({
              fontFamily: '"blocks/'+encodeURIComponent(block_id)+'", serif'
            });
            var _aside = cp_fig.closest('figure').next('aside');
            if (_aside.length) {
              _aside.find('dl:eq(0)')
                    .append('<dt>'+_('Font used above')+'</dt>' +
                            '<dd><a href="/font/'+encodeURIComponent(cp_font)+'">'+cp_fam+'</a></dd>');
            }
          }
        });
      }
    }
  }
}
