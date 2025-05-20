import base64
import io
import pyperclip
from PIL import Image, ImageGrab

def nearest_power_of_2_smaller(x):
    """Calculate the nearest power of 2 smaller than or equal to x."""
    if x <= 0:
        return 1
    return 2 ** (x.bit_length() - 1)

def optimize_image_to_smaller_power_of_2(image):
    """Resize image to the nearest smaller power-of-2 dimensions."""
    img = image.convert("RGBA")  # Ensure RGBA format
    original_width, original_height = img.width, img.height
    new_width = nearest_power_of_2_smaller(original_width)
    new_height = nearest_power_of_2_smaller(original_height)
    img = img.resize((new_width, new_height), Image.Resampling.BOX)
    return img, new_width, new_height

def prepend_dimensions_to_binary_string(rgba_data, width, height):
    """Prepend dimensions to the binary string."""
    dimensions = width.to_bytes(4, 'big') + height.to_bytes(4, 'big')  # 4 bytes each for width and height
    return dimensions + rgba_data

def format_as_lua_string(binary_data):
    """Format binary data as a Lua-compatible string."""
    lua_compatible_string = ''.join(f'\\x{byte:02x}' for byte in binary_data)
    return lua_compatible_string

def get_image_from_clipboard():
    """Retrieve the first valid image from the clipboard."""
    clipboard_content = ImageGrab.grabclipboard()

    if clipboard_content is None:
        raise ValueError("No image found in clipboard. Copy an image first.")

    if isinstance(clipboard_content, list):  # Windows clipboard sometimes returns file paths
        for item in clipboard_content:
            if isinstance(item, str):  # If it's a file path
                try:
                    return Image.open(item)  # Try opening the image file
                except Exception:
                    continue  # Ignore invalid image files

        raise ValueError("Clipboard contains multiple items, but no valid images.")

    if isinstance(clipboard_content, Image.Image):  # Directly copied image
        return clipboard_content

    raise ValueError("Clipboard does not contain an image.")

def main():
    try:
        # Grab the first valid image from clipboard
        image = get_image_from_clipboard()

        # Optimize the image
        optimized_img, width, height = optimize_image_to_smaller_power_of_2(image)

        # Convert the image to raw binary (RGBA format)
        rgba_data = optimized_img.tobytes()

        # Prepend dimensions to the binary data
        binary_data = prepend_dimensions_to_binary_string(rgba_data, width, height)

        # Format as a Lua-compatible string
        lua_compatible_string = format_as_lua_string(binary_data)

        # Copy the Lua-compatible binary string to clipboard
        pyperclip.copy(lua_compatible_string)
        print(f" Image successfully converted and copied to clipboard! Dimensions: {width}x{height}")

    except Exception as e:
        print(f" Error: {e}. Make sure an image is copied to the clipboard.")

if __name__ == "__main__":
    main()
