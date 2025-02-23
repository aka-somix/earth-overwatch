<script setup lang="ts">
import { useRouter } from 'vue-router';

const router = useRouter();

const navigateToHome = () => {
  router.push('/map');
};
</script>

<template>
  <div class="splash-screen">
    <!-- Background Video -->
    <video autoplay muted playsinline class="background-video">
      <source src="/videos/splash.mp4" type="video/mp4" />
    </video>

    <!-- Overlay Content -->
    <div class="content">
      <h1 class="title">🌍 Earth Overwatch</h1>
      <p class="subtitle">Dive into the world's environmental challenges and take action.</p>
      <button @click="navigateToHome" class="cta-button">Start Exploring</button>
    </div>
  </div>
</template>

<style scoped>
/* Fullscreen splash screen */
.splash-screen {
  position: relative;
  width: 100vw;
  height: 100vh;
  overflow: hidden;
  display: flex;
  justify-content: center;
  align-items: center;
}

.content {
    display: flex;
    flex-direction: column;
    justify-content: flex-start;
    align-items: center;
    
}

/* Background Video */
.background-video {
  position: absolute;
  top: 50%;
  left: 50%;
  width: 100vw;
  height: 100vh;
  object-fit: cover;
  transform: translate(-50%, -50%);
  z-index: -1;
  filter: blur(4px) hue-rotate(-40deg);
}


/* Title Styling */
.title {
  font-size: 5rem;
  text-align: center;
  font-weight: bold;
  text-transform: uppercase;
  text-shadow: 0 0 10px rgba(255, 255, 255, 0.8);
  animation: slideDown 1s ease-in-out;
}

/* Subtitle */
.subtitle {
  font-size: 1.2rem;
  margin-top: 10px;
  opacity: 0.9;
  animation: fadeIn 2s ease-in-out;
  color: white
}

/* Call-to-Action Button */
.cta-button {
  width: 40vw;
  margin-top: 20px;
  padding: 15px 30px;
  font-size: 1.2rem;
  font-weight: bold;
  color: white;
  background: linear-gradient(45deg, #1bac81, #008435);
  border: none;
  border-radius: 50px;
  cursor: pointer;
  box-shadow: 0 5px 15px rgba(29, 159, 77, 0.5);
  transition: all 0.3s ease-in-out;
  animation: popIn 1.5s ease-in-out;
}

.cta-button:hover {
  transform: scale(1.05);
  box-shadow: 0 8px 20px rgba(29, 159, 77, 0.5);
}

/* Animations */
@keyframes fadeIn {
  from {
    opacity: 0;
  }
  to {
    opacity: 1;
  }
}

@keyframes slideDown {
  from {
    transform: translateY(-20px);
    opacity: 0;
  }
  to {
    transform: translateY(0);
    opacity: 1;
  }
}

@keyframes popIn {
  from {
    transform: scale(0.9);
    opacity: 0;
  }
  to {
    transform: scale(1);
    opacity: 1;
  }
}
</style>