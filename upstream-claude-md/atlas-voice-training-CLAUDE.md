# CLAUDE.md

**Local-only file.** This repo is an upstream clone of `briankelley/atlas-voice-training`. CLAUDE.md is added to `.git/info/exclude` and never pushed to upstream.

## Purpose

Dockerized OpenWakeWord fine-tuning pipeline. Generates a custom wake-word model (~200 KB TFLite/ONNX) for the hapax-daimonion voice daemon. Trains on synthetic Piper TTS samples, augmented with MUSAN background noise and MIT impulse-response reverb.

## Build & run

```bash
./train-wakeword.sh        # primary entry — Docker-based, recommended
./train.sh                 # bare-metal fallback, no Docker (testing only)
```

`train-wakeword.sh` builds the image from `Dockerfile.training`, prompts the operator for confirmation, then runs the container with the dataset mounted to `/data` and outputs to `docker-output/` on the host.

```bash
python validate_model.py docker-output/hey_atlas.tflite [threshold]
```

Loads a TFLite model, runs it against `positive_features_test.npy` and `negative_features_test.npy`, prints accuracy / recall / precision / FP-per-hour.

## Config

`hey_atlas_config.yml` controls phrase, sample counts, augmentation rounds, training steps, and dataset paths. Empirically validated defaults: 50k samples, 2 augmentation rounds, 100k training steps, 32 neurons.

`container-entrypoint.sh` generates the runtime config from env vars passed by the host wrapper: `WAKE_WORD`, `MODEL_NAME`, `N_SAMPLES`, `AUGMENTATION_ROUNDS`, `TRAINING_STEPS`, `LAYER_SIZE`.

## Dataset

`atlas-voice-training-data.tar.gz` (~20 GB on HuggingFace) bundles ACAV100M features (17 GB), MUSAN music (4.6 GB), MIT RIRs pre-converted to 16 kHz mono (300 MB), validation features (177 MB), Piper TTS model (200 MB), and embedding models (~10 MB). Mount via `/data` volume. `rebuild-tarball.sh` re-builds the tarball from upstream sources (requires ~60 GB disk, ffmpeg, huggingface-cli auth) — one-time setup.

## Outputs

- `docker-output/{MODEL_NAME}.tflite` — TFLite model (~200 KB), the deployable artifact
- `docker-output/{MODEL_NAME}.onnx` — ONNX export
- Final stdout block: accuracy %, recall %, false positives/hour

## Deploy to hapax-daimonion

```bash
cp docker-output/hey_atlas.tflite ~/.local/share/openwakeword/
systemctl --user restart hapax-daimonion.service
```

OpenWakeWord auto-discovers models in `~/.local/share/openwakeword/` at daemon startup. No code changes needed in hapax-daimonion.

## Gotchas

- **Docker shared memory**: defaults to 64 MB; PyTorch DataLoader needs >2 GB. The wrapper sets `--shm-size` automatically.
- **GPU requirement**: NVIDIA only (CUDA 11.7). Fails without nvidia-container-toolkit.
- **Pinned dependencies**: PyTorch 1.13.1, TensorFlow 2.8.1, Python 3.10. Modern Python breaks these — the container pins them deliberately.
- **HuggingFace rate limits**: per-file downloads get throttled. Use the bundled tarball instead.
- **PYTHONUNBUFFERED=1** is set in the container so progress shows in `docker logs`.
- **Final-step segfault is harmless**: model is saved before cleanup. The training script wraps the last step in `|| true`.
- **MIT RIRs are 32 kHz upstream**: the bundled tarball pre-converts them to 16 kHz mono. `rebuild-tarball.sh` handles the conversion via ffmpeg.

## Empirical findings (from upstream README testing tables)

- Two-word wake phrases significantly outperform single words.
- 50k synthetic samples is the optimal point — more samples do not improve accuracy.
- 100k training steps is sufficient — additional steps overfit.

## Integration notes

The migration script `hapax-council/scripts/migrate-voice-to-daimonion.sh` copies wake-word models from the legacy `~/.local/share/hapax-voice` namespace to `~/.local/share/hapax-daimonion`. New models go directly to `~/.local/share/openwakeword/` — no migration needed.
