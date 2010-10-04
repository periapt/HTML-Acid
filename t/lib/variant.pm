package variant;

sub args {
    return (
        url_regex=>qr{
            \A                  # start of string
            (?:
                (?:
                    http://\w[\w\.]{1,20}\w
                )                  # optional external ref
                |
                (?:
                    /                   # 
                    \w                  # at least one normal character
                    [\w\-/]*            # 
                )
            )
            (?:\#[\w\-]+)?      # optional anchor
            \z                  # end of string
        }xms,
        tag_hierarchy => {
            h3 => '',
            p => '',
            a => 'p',
            div => 'p',
            img => 'div',
            em => 'p',
            strong => 'p',
        },
        img_height_default=>100,
        img_width_default=>200,
    );
}

1

