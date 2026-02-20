shader_type canvas_item;

uniform float progress : hint_range(0.0, 1.0); // 0 = início do aim, 1 = carregado
uniform float glow_strength : hint_range(0.0, 5.0) = 2.0;
uniform float noise_speed : hint_range(0.0, 5.0) = 1.5;
uniform vec4 color_start : source_color = vec4(0.2, 0.8, 1.0, 1.0);
uniform vec4 color_end : source_color = vec4(1.0, 0.2, 0.2, 1.0);

float random(vec2 uv) {
    return fract(sin(dot(uv.xy, vec2(12.9898,78.233))) * 43758.5453);
}

void fragment() {
    float t = TIME * noise_speed;

    // Posicao da UV ao longo do Line2D
    float u = UV.x;

    // transição gradual de cor
    vec4 col = mix(color_start, color_end, progress);

    // ruído animado
    float noise = random(vec2(u * 20.0 + t, UV.y + t));

    // efeito de energia pulsante
    float pulse = sin(TIME * 10.0) * 0.2 + 0.8;

    // intensidade do brilho aumenta conforme "carrega"
    float energy = progress * glow_strength;

    COLOR = col * (pulse + noise * energy);
}
