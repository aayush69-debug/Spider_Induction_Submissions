import argparse
import os
import hashlib
from cryptography.hazmat.primitives.ciphers import Cipher, algorithms, modes
from cryptography.hazmat.primitives import padding, hashes
from cryptography.hazmat.primitives.kdf.pbkdf2 import PBKDF2HMAC
from cryptography.hazmat.primitives.asymmetric import rsa, padding as asym_padding
from cryptography.hazmat.primitives import serialization
from cryptography.hazmat.backends import default_backend


def generate_keys():
    """Generates a 2048-bit RSA keypair and saves them to PEM files."""
    private_key = rsa.generate_private_key(
        public_exponent=65537,
        key_size=2048,
        backend=default_backend()
    )
    public_key = private_key.public_key()


    with open("private.pem", "wb") as f:
        f.write(private_key.private_bytes(
            encoding=serialization.Encoding.PEM,
            format=serialization.PrivateFormat.TraditionalOpenSSL,
            encryption_algorithm=serialization.NoEncryption()
        ))
    

    with open("public.pem", "wb") as f:
        f.write(public_key.public_bytes(
            encoding=serialization.Encoding.PEM,
            format=serialization.PublicFormat.SubjectPublicKeyInfo
        ))
    print("[+] RSA Keypair generated: public.pem and private.pem")



def encrypt_file(filepath, verify=False):
    """Encrypts a file using Hybrid RSA + AES-256-CBC."""
    if not os.path.exists("public.pem"):
        print("[-] Error: public.pem not found. Run 'python cryptovault.py keygen' first.")
        return


    with open("public.pem", "rb") as f:
        public_key = serialization.load_pem_public_key(f.read(), backend=default_backend())


    with open(filepath, "rb") as f:
        plaintext = f.read()


    file_hash = b""
    if verify:
        digest = hashes.Hash(hashes.SHA256(), backend=default_backend())
        digest.update(plaintext)
        file_hash = digest.finalize()


    aes_key = os.urandom(32) 
    iv = os.urandom(16)      


    padder = padding.PKCS7(128).padder()
    padded_data = padder.update(plaintext) + padder.finalize()
    cipher = Cipher(algorithms.AES(aes_key), modes.CBC(iv), backend=default_backend())
    encryptor = cipher.encryptor()
    ciphertext = encryptor.update(padded_data) + encryptor.finalize()


    encrypted_aes_key = public_key.encrypt(
        aes_key,
        asym_padding.OAEP(
            mgf=asym_padding.MGF1(algorithm=hashes.SHA256()),
            algorithm=hashes.SHA256(),
            label=None
        )
    )



    out_filepath = filepath + ".enc"
    with open(out_filepath, "wb") as f:
        f.write(len(encrypted_aes_key).to_bytes(4, byteorder='big'))
        f.write(encrypted_aes_key)
        f.write(iv)
        f.write(b'\x01' if verify else b'\x00') 
        if verify:
            f.write(file_hash)
        f.write(ciphertext)

    print(f"[+] File successfully encrypted to {out_filepath}")



def decrypt_file(filepath):
    """Decrypts a Hybrid RSA + AES encrypted file."""
    if not os.path.exists("private.pem"):
        print("[-] Error: private.pem not found.")
        return


    with open("private.pem", "rb") as f:
        private_key = serialization.load_pem_private_key(f.read(), password=None, backend=default_backend())

    with open(filepath, "rb") as f:
        data = f.read()

    try:

        key_len = int.from_bytes(data[0:4], byteorder='big')
        idx = 4
        
        encrypted_aes_key = data[idx : idx+key_len]
        idx += key_len
        
        iv = data[idx : idx+16]
        idx += 16
        
        verify_flag = data[idx : idx+1]
        idx += 1
        
        stored_hash = b""
        if verify_flag == b'\x01':
            stored_hash = data[idx : idx+32]
            idx += 32
            
        ciphertext = data[idx:]


        aes_key = private_key.decrypt(
            encrypted_aes_key,
            asym_padding.OAEP(
                mgf=asym_padding.MGF1(algorithm=hashes.SHA256()),
                algorithm=hashes.SHA256(),
                label=None
            )
        )


        cipher = Cipher(algorithms.AES(aes_key), modes.CBC(iv), backend=default_backend())
        decryptor = cipher.decryptor()
        padded_plaintext = decryptor.update(ciphertext) + decryptor.finalize()

        unpadder = padding.PKCS7(128).unpadder()
        plaintext = unpadder.update(padded_plaintext) + unpadder.finalize()


        if verify_flag == b'\x01':
            digest = hashes.Hash(hashes.SHA256(), backend=default_backend())
            digest.update(plaintext)
            calculated_hash = digest.finalize()
            
            if calculated_hash != stored_hash:
                print("[-] TAMPER WARNING: The file integrity check failed! It may have been corrupted.")
                return
            else:
                print("[+] Hash verified: File integrity is intact.")


        out_filepath = filepath.replace(".enc", ".decrypted")
        with open(out_filepath, "wb") as f:
            f.write(plaintext)
            
        print(f"[+] File successfully decrypted to {out_filepath}")

    except ValueError as e:
        print("[-] Decryption failed! Wrong private key or corrupted file data.")



if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="CryptoVault - Hybrid Encryption Tool")
    subparsers = parser.add_subparsers(dest="command", help="Commands to run")


    keygen_parser = subparsers.add_parser("keygen", help="Generate RSA Keypair")


    encrypt_parser = subparsers.add_parser("encrypt", help="Encrypt a file")
    encrypt_parser.add_argument("file", help="File to encrypt")
    encrypt_parser.add_argument("--verify", action="store_true", help="Embed a SHA-256 hash for integrity verification")


    decrypt_parser = subparsers.add_parser("decrypt", help="Decrypt a file")
    decrypt_parser.add_argument("file", help="File to decrypt (.enc)")

    args = parser.parse_args()

    if args.command == "keygen":
        generate_keys()
    elif args.command == "encrypt":
        encrypt_file(args.file, args.verify)
    elif args.command == "decrypt":
        decrypt_file(args.file)
    else:
        parser.print_help()