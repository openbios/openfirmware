// See license at end of file

/* Simple XCB application drawing a box in a window */

#include <xcb/xcb.h>
#include <stdlib.h>

xcb_connection_t    *c;
xcb_screen_t        *s;
xcb_window_t         w;
xcb_gcontext_t       g;
xcb_colormap_t       colormap;

uint32_t rgbcolor(uint16_t b, uint16_t g, uint16_t r)
{
    xcb_alloc_color_reply_t *rep;

    rep = xcb_alloc_color_reply (c, xcb_alloc_color (c, colormap, r<<8, g<<8, b<<8), NULL);

    return rep->pixel;
}

uint32_t color565(uint32_t color)
{
    uint16_t r, g, b;
    xcb_alloc_color_reply_t *rep;

#if 0
    r = (color>>11) << 11;
    g = ((color>>5) & 0x3f) << 10;
    b = (color & 0x1f) << 11;

    rep = xcb_alloc_color_reply (c, xcb_alloc_color (c, colormap, r, g, b), NULL);

    return rep->pixel;
#else
    r = (color>>11) << 3;
    g = ((color>>5) & 0x3f) << 2;
    b = (color & 0x1f) << 3;

    return (r<<16) | (g<<8) | b;
#endif
}

void fill_rectangle(uint32_t height, uint32_t width, uint32_t y, uint32_t x, uint32_t color)
{
    uint32_t value[1];
    xcb_rectangle_t  r;

    value[0] = color;
    xcb_change_gc (c, g, XCB_GC_FOREGROUND, value);

    r.x = x; r.y = y; r.width = width; r.height = height;

    xcb_poly_fill_rectangle(c, w, g,  1, &r);
    xcb_flush(c);
}

int open_window(uint32_t height, uint32_t width) {
    uint32_t             mask;
    uint32_t             values[2];

                       /* open connection with the server */
    c = xcb_connect(NULL,NULL);
    if (xcb_connection_has_error(c)) {
        return -1;
    }

    /* get the first screen */
    s = xcb_setup_roots_iterator( xcb_get_setup(c) ).data;

    colormap = s->default_colormap;

    /* create black graphics context */
    g = xcb_generate_id(c);
    w = s->root;
    mask = XCB_GC_FOREGROUND | XCB_GC_GRAPHICS_EXPOSURES;
    values[0] = s->black_pixel;
    values[1] = 0;
    xcb_create_gc(c, g, w, mask, values);

    /* create window */
    w = xcb_generate_id(c);
/*
  mask = XCB_CW_BACK_PIXEL | XCB_CW_EVENT_MASK;
  values[0] = s->white_pixel;
  values[1] = XCB_EVENT_MASK_EXPOSURE | XCB_EVENT_MASK_KEY_PRESS;
*/
    mask = XCB_CW_BACK_PIXEL;
    values[0] = s->white_pixel;
    xcb_create_window(c, s->root_depth, w, s->root,
                      0, 0, width, height, 1,
                      XCB_WINDOW_CLASS_INPUT_OUTPUT, s->root_visual,
                      mask, values);

    /* map (show) the window */
    xcb_map_window(c, w);
    xcb_flush(c);
    return 0;
}

long close_window()
{
    xcb_disconnect(c);
    return 0;
}

#if 0

int main()
{
#if 0
    xcb_generic_event_t *e;

    int                  done = 0;
#endif

    (void)open_window(900, 1200);

    fill_rectangle(60, 60, 20, 20, rgbcolor(0xff, 0, 0xff));
#if 0
    /* event loop */
    while (!done && (e = xcb_wait_for_event(c))) {
        switch (e->response_type & ~0x80) {
        case XCB_EXPOSE:    /* draw or redraw the window */
            fill_rectangle(60, 60, 20, 20, rgbcolor(0xff, 0, 0xff));
            break;
        case XCB_KEY_PRESS:  /* exit on key press */
            done = 1;
            break;
        }
        free(e);
    }
#endif

    sleep(10);
                       /* close connection to server */
    close_window();

    return 0;
}
#endif

// LICENSE_BEGIN
// Copyright (c) 2009 FirmWorks
// 
// Permission is hereby granted, free of charge, to any person obtaining
// a copy of this software and associated documentation files (the
// "Software"), to deal in the Software without restriction, including
// without limitation the rights to use, copy, modify, merge, publish,
// distribute, sublicense, and/or sell copies of the Software, and to
// permit persons to whom the Software is furnished to do so, subject to
// the following conditions:
// 
// The above copyright notice and this permission notice shall be
// included in all copies or substantial portions of the Software.
// 
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
// EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
// MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
// NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
// LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
// OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
// WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//
// LICENSE_END
