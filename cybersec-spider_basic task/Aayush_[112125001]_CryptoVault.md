#Stage 1: Caesar Lock

Why is Caesar trivially breakable? It has an incredibly small keyspace. There are only 25 possible shifts in the English alphabet, meaning a computer (or a human) can brute-force all possibilities in seconds.

What property of language makes frequency analysis work? Natural languages have highly predictable distributions of letters. In English, 'E' is the most common letter. By finding the most frequent character in the ciphertext and mapping it to 'E', the entire cipher shift can be reverse-engineered without guessing.

#Stage 2: Hash Guard

Why do you need both? Encryption provides confidentiality (preventing unauthorized reading), while hashing provides integrity (preventing unauthorized modification). Without a hash, an attacker could blindly alter the ciphertext, and the recipient wouldn't know the file was corrupted or tampered with until they tried to read the garbled output.

#Stage 3: AES Upgrade

What goes wrong if the IV is reused? Reusing an IV with the same encryption key means identical plaintexts will result in identical ciphertexts. This leaks structural patterns about the data to an attacker.

What does PBKDF2 add that a plain hash doesn't? PBKDF2 introduces a "salt" (which defeats pre-computed dictionary or "rainbow table" attacks) and uses thousands of iterations (key stretching). This makes brute-forcing the password computationally expensive and incredibly slow.

#Stage 4: RSA Key Exchange

Why can't we encrypt the whole file with RSA directly? RSA relies on complex math (prime factorization) which is computationally very slow, making it impractical for large data. Additionally, RSA has a strict size limit: it cannot encrypt data larger than its key size.

How does this hybrid approach relate to how HTTPS works? HTTPS (TLS/SSL) uses the exact same hybrid model. When you visit a website, your browser uses RSA (asymmetric) to securely transmit a temporary symmetric session key. Once the symmetric key is shared, the browser switches to AES (symmetric) to quickly encrypt the actual web traffic.