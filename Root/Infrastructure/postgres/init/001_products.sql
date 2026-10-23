CREATE TABLE IF NOT EXISTS products (
    id          text PRIMARY KEY,
    name        text NOT NULL,
    description text NOT NULL,
    color       text NOT NULL,
    quantity    integer NOT NULL CHECK (quantity >= 0),
    barcode     text NOT NULL UNIQUE,
    qr_code     text NOT NULL UNIQUE
);

INSERT INTO products (id, name, description, color, quantity, barcode, qr_code)
VALUES
    (
        'PHN-001',
        'Aurora X1',
        '6.4-inch OLED display, 128 GB storage, dual 50 MP camera, 5000 mAh battery.',
        'Midnight Black',
        12,
        '2000000000015',
        '{"id":"PHN-001","type":"phone"}'
    ),
    (
        'PHN-002',
        'Nova S2',
        '6.5-inch AMOLED display, 256 GB storage, triple camera, 4800 mAh battery.',
        'Ocean Blue',
        7,
        '2000000000022',
        '{"id":"PHN-002","type":"phone"}'
    ),
    (
        'PHN-003',
        'Pulse 7',
        '6.1-inch LCD display, 64 GB storage, dual camera, 4500 mAh battery.',
        'Arctic White',
        0,
        '2000000000039',
        '{"id":"PHN-003","type":"phone"}'
    ),
    (
        'PHN-004',
        'Vertex Pro',
        '6.7-inch LTPO OLED display, 512 GB storage, 108 MP camera, 5000 mAh battery.',
        'Graphite Gray',
        4,
        '2000000000046',
        '{"id":"PHN-004","type":"phone"}'
    ),
    (
        'PHN-005',
        'Lumen Mini',
        '5.8-inch OLED display, 128 GB storage, compact flagship, 4000 mAh battery.',
        'Coral Pink',
        15,
        '2000000000053',
        '{"id":"PHN-005","type":"phone"}'
    ),
    (
        'PHN-006',
        'Orion Max',
        '6.8-inch AMOLED display, 256 GB storage, 200 MP camera, 5500 mAh battery.',
        'Forest Green',
        0,
        '2000000000060',
        '{"id":"PHN-006","type":"phone"}'
    ),
    (
        'PHN-007',
        'Aero Lite',
        '6.3-inch OLED display, 128 GB storage, lightweight body, 4800 mAh battery.',
        'Sky Blue',
        9,
        '2000000000077',
        '{"id":"PHN-007","type":"phone"}'
    ),
    (
        'PHN-008',
        'Titan Edge',
        '6.6-inch OLED display, 256 GB storage, titanium frame, 5000 mAh battery.',
        'Titanium Silver',
        3,
        '2000000000084',
        '{"id":"PHN-008","type":"phone"}'
    ),
    (
        'PHN-009',
        'Zenith 5G',
        '6.5-inch OLED display, 256 GB storage, 5G, 5000 mAh battery.',
        'Deep Purple',
        0,
        '2000000000091',
        '{"id":"PHN-009","type":"phone"}'
    ),
    (
        'PHN-010',
        'Solstice',
        '6.4-inch AMOLED display, 128 GB storage, 64 MP camera, 4600 mAh battery.',
        'Sunset Gold',
        6,
        '2000000000107',
        '{"id":"PHN-010","type":"phone"}'
    )
ON CONFLICT (id) DO NOTHING;
