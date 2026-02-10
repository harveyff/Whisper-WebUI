FROM debian:bookworm-slim AS builder

RUN apt-get update && \
    apt-get install -y curl git python3 python3-pip python3-venv build-essential && \
    rm -rf /var/lib/apt/lists/* /var/cache/apt/archives/* && \
    mkdir -p /Whisper-WebUI

WORKDIR /Whisper-WebUI

COPY requirements.txt .

RUN python3 -m venv venv && \
    . venv/bin/activate && \
    pip install --upgrade pip setuptools wheel && \
    pip install "setuptools<70"

# Install PyTorch first
RUN . venv/bin/activate && \
    pip install "torch>=2.8.0,<2.9.0" "torchaudio>=2.8.0,<2.9.0" --index-url https://download.pytorch.org/whl/cu128

# Install other Python packages (excluding git dependencies)
RUN . venv/bin/activate && \
    pip install matplotlib faster-whisper==1.1.1 transformers==4.47.1 gradio==5.29.0 gradio-i18n==0.3.1 pytubefix ruamel.yaml==0.18.6 pyannote.audio==3.3.2

# Install git dependencies manually to avoid build isolation issues
RUN . venv/bin/activate && \
    cd /tmp && \
    git clone --depth 1 https://github.com/jhj0517/jhj0517-whisper.git && \
    /Whisper-WebUI/venv/bin/pip install --no-build-isolation /tmp/jhj0517-whisper && \
    rm -rf /tmp/jhj0517-whisper && \
    cd /tmp && \
    git clone --depth 1 https://github.com/jhj0517/ultimatevocalremover_api.git && \
    /Whisper-WebUI/venv/bin/pip install --no-build-isolation --no-deps /tmp/ultimatevocalremover_api && \
    /Whisper-WebUI/venv/bin/pip install openunmix && \
    rm -rf /tmp/ultimatevocalremover_api && \
    cd /tmp && \
    git clone --depth 1 https://github.com/jhj0517/pyrubberband.git && \
    cd pyrubberband && \
    /Whisper-WebUI/venv/bin/python setup.py develop && \
    cd /Whisper-WebUI && \
    rm -rf /tmp/pyrubberband


FROM debian:bookworm-slim AS runtime

RUN apt-get update && \
    apt-get install -y curl ffmpeg python3 && \
    rm -rf /var/lib/apt/lists/* /var/cache/apt/archives/*

WORKDIR /Whisper-WebUI

COPY . .
COPY --from=builder /Whisper-WebUI/venv /Whisper-WebUI/venv
RUN mkdir -p /Whisper-WebUI/configs_default && \
    cp -a /Whisper-WebUI/configs/. /Whisper-WebUI/configs_default/

VOLUME [ "/Whisper-WebUI/models" ]
VOLUME [ "/Whisper-WebUI/outputs" ]

ENV PATH="/Whisper-WebUI/venv/bin:$PATH"
ENV LD_LIBRARY_PATH=/Whisper-WebUI/venv/lib64/python3.11/site-packages/nvidia/cublas/lib:/Whisper-WebUI/venv/lib64/python3.11/site-packages/nvidia/cudnn/lib

ENTRYPOINT [ "python", "app.py" ]
