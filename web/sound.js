// Synthesized locally: no audio downloads, microphone, or third-party services.
let audio;
window.bulletSound = function(kind) {
  try {
    audio ??= new (window.AudioContext || window.webkitAudioContext)();
    audio.resume();
    const notes = kind === 'bell' ? [660, 880, 660] : kind === 'win' ? [523, 659, 784, 1047] : [784, 1047];
    notes.forEach((frequency, index) => {
      const oscillator = audio.createOscillator();
      const gain = audio.createGain();
      const start = audio.currentTime + index * .13;
      oscillator.type = 'sine';
      oscillator.frequency.value = frequency;
      gain.gain.setValueAtTime(0, start);
      gain.gain.linearRampToValueAtTime(.08, start + .02);
      gain.gain.exponentialRampToValueAtTime(.001, start + .3);
      oscillator.connect(gain);
      gain.connect(audio.destination);
      oscillator.start(start);
      oscillator.stop(start + .32);
    });
  } catch (_) { /* Visual feedback remains available if audio is blocked. */ }
};
