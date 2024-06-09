import streamlit as st
from transformers import pipeline

# Load the model with error handling
@st.cache(allow_output_mutation=True)
def load_model():
    try:
        # Replace 'model-name' with the actual model name from Hugging Face
        model = pipeline("text-generation", model="Bin12345/AutoCoder")
        return model
    except Exception as e:
        st.error(f"Error loading model: {e}")
        return None

model = load_model()

# Streamlit app title
st.title('AI Code Generator')

# Check if the model is loaded
if model:
    # User input for the requirement description
    requirement = st.text_area("Enter your requirement description here:")

    # User input for the programming language
    language = st.text_input("Enter the programming language:")

    # Generate button
    if st.button('Generate Code'):
        try:
            # Use the model to generate code
            generated_code = model(f"Write {language} code for: {requirement}", max_length=512)[0]['generated_text']
            
            # Display the generated code
            st.code(generated_code)
        except Exception as e:
            st.error(f"Error generating code: {e}")
else:
    st.error("Model not loaded. Please check the model name and internet connection.")

# Instructions for deployment can be found in the Streamlit documentation
# Please refer to the official Streamlit deployment guide for detailed steps
