'use client'

import { motion, useScroll, useTransform, useInView, AnimatePresence } from 'framer-motion'
import { useRef, useState, useEffect } from 'react'
import { ArrowRight, Sparkles, Users, Zap, Shield, Globe, CheckCircle, Menu, X, Github, Twitter, Linkedin, Mail, MessageCircle, Calendar, User, Bell, Timer, Flame, Star, Heart, Eye, TrendingUp } from 'lucide-react'
import AnimatedHiveLogo from '../components/AnimatedHiveLogo'
import Image from 'next/image'
import { gsap } from 'gsap'
import { ScrollTrigger } from 'gsap/ScrollTrigger'

// Register GSAP plugins
if (typeof window !== 'undefined') {
  gsap.registerPlugin(ScrollTrigger)
}

const fadeInUp = {
  initial: { opacity: 0, y: 60 },
  animate: { opacity: 1, y: 0 },
  transition: { duration: 0.8, ease: [0.25, 0.8, 0.25, 1] }
}

const stagger = {
  animate: {
    transition: {
      staggerChildren: 0.15
    }
  }
}

const chaosVariants = {
  initial: { opacity: 0, scale: 0.8, rotate: -5 },
  animate: { 
    opacity: 1, 
    scale: 1, 
    rotate: [0, 2, -1, 0],
    transition: { 
      duration: 0.6, 
      rotate: { repeat: Infinity, duration: 3, ease: "easeInOut" }
    }
  }
};

const glitchText = {
  initial: { opacity: 1 },
  animate: { 
    opacity: [1, 0.8, 1, 0.9, 1],
    x: [0, -2, 2, -1, 0],
    transition: { 
      duration: 2,
      repeat: Infinity,
      repeatType: "reverse" as const
    }
  }
};

const Navigation = () => {
  const [isOpen, setIsOpen] = useState(false)
  const [scrolled, setScrolled] = useState(false)

  useEffect(() => {
    const handleScroll = () => {
      setScrolled(window.scrollY > 50)
    }
    window.addEventListener('scroll', handleScroll)
    return () => window.removeEventListener('scroll', handleScroll)
  }, [])

  return (
    <motion.nav
      initial={{ y: -100 }}
      animate={{ y: 0 }}
      className={`fixed top-0 left-0 right-0 z-50 transition-all duration-500 ${
        scrolled ? 'bg-hive-black/90 backdrop-blur-lg border-b border-white/10' : 'bg-transparent'
      }`}
    >
      <div className="max-w-7xl mx-auto px-6 py-4">
        <div className="flex items-center justify-between">
          {/* Animated Logo */}
          <AnimatedHiveLogo variant="nav" size={80} />

          {/* Desktop Navigation */}
          <div className="hidden md:flex items-center gap-8">
            <a href="#features" className="text-white/80 hover:text-white transition-colors">Features</a>
            <a href="#about" className="text-white/80 hover:text-white transition-colors">About</a>
            <a href="#contact" className="text-white/80 hover:text-white transition-colors">Contact</a>
            <motion.button
              className="px-6 py-2 bg-hive-gold text-hive-black font-semibold rounded-full hover:bg-hive-gold-hover transition-all duration-300"
              whileHover={{ scale: 1.05 }}
              whileTap={{ scale: 0.98 }}
            >
              Get Started
            </motion.button>
          </div>

          {/* Mobile Menu Button */}
          <button
            className="md:hidden text-white"
            onClick={() => setIsOpen(!isOpen)}
          >
            {isOpen ? <X className="w-6 h-6" /> : <Menu className="w-6 h-6" />}
          </button>
        </div>

        {/* Mobile Navigation */}
        <motion.div
          initial={false}
          animate={{ height: isOpen ? 'auto' : 0, opacity: isOpen ? 1 : 0 }}
          className="md:hidden overflow-hidden"
        >
          <div className="py-4 space-y-4">
            <a href="#features" className="block text-white/80 hover:text-white transition-colors">Features</a>
            <a href="#about" className="block text-white/80 hover:text-white transition-colors">About</a>
            <a href="#contact" className="block text-white/80 hover:text-white transition-colors">Contact</a>
            <button className="w-full mt-4 px-6 py-2 bg-hive-gold text-hive-black font-semibold rounded-full hover:bg-hive-gold-hover transition-all duration-300">
              Get Started
            </button>
          </div>
        </motion.div>
      </div>
    </motion.nav>
  )
}

const ChaosHeader = () => {
  const [isMenuOpen, setIsMenuOpen] = useState(false);

  return (
    <motion.header
      initial={{ y: -100 }}
      animate={{ y: 0 }}
      className="fixed top-0 left-0 right-0 z-50 bg-black/90 backdrop-blur-lg border-b border-hive-gold/20"
    >
      <div className="max-w-7xl mx-auto px-6 py-4">
        <div className="flex items-center justify-between">
          <motion.div 
            className="flex items-center gap-3"
            whileHover={{ scale: 1.05 }}
          >
            <div className="relative">
              <Image 
                src="/images/hivelogo.png" 
                alt="HIVE" 
                width={40} 
                height={40}
                className="rounded-lg"
              />
              <motion.div
                className="absolute -top-1 -right-1 w-3 h-3 bg-hive-gold rounded-full"
                animate={{ 
                  scale: [1, 1.3, 1],
                  opacity: [1, 0.7, 1]
                }}
                transition={{ duration: 1, repeat: Infinity }}
              />
            </div>
            <span className="text-2xl font-bold text-white">HIVE</span>
          </motion.div>

          <motion.button
            className="px-6 py-2 bg-hive-gold text-black font-bold rounded-full hover:bg-yellow-400 transition-all"
            whileHover={{ scale: 1.05, rotate: 1 }}
            whileTap={{ scale: 0.95 }}
          >
            JOIN THE CHAOS
          </motion.button>
        </div>
      </div>
    </motion.header>
  );
};

const Counter = ({ target, duration = 2 }: { target: number; duration?: number }) => {
  const [count, setCount] = useState(0);
  const countRef = useRef(null);

  useEffect(() => {
    const obj = { val: 0 };
    gsap.to(obj, {
      val: target,
      duration,
      ease: "power2.out",
      onUpdate: () => setCount(Math.round(obj.val)),
      scrollTrigger: {
        trigger: countRef.current,
        start: "top center",
        once: true
      }
    });
  }, [target, duration]);

  return <span ref={countRef}>{count.toLocaleString()}</span>;
};

const HeroSection = () => {
  const heroRef = useRef(null);
  const dotRef = useRef<HTMLDivElement>(null);
  const titleRef = useRef(null);
  const subtitleRef = useRef(null);

  useEffect(() => {
    const ctx = gsap.context(() => {
      // Initial state
      gsap.set(titleRef.current, { opacity: 0, scale: 0.8 });
      gsap.set(subtitleRef.current, { opacity: 0, y: 30 });

      // Hero dot pulse
      gsap.fromTo(dotRef.current,
        { scale: 0 },
        { 
          scale: 1, 
          yoyo: true, 
          repeat: -1, 
          duration: 1.5, 
          ease: "power2.inOut",
          boxShadow: "0 0 0 0 rgba(255, 199, 0, 0.7)"
        }
      );

      // Dot click expansion
      const expandDot = () => {
        gsap.to(dotRef.current, {
          scale: 15,
          opacity: 0,
          duration: 1.5,
          ease: "power3.out"
        });

        gsap.to(titleRef.current, {
          opacity: 1,
          scale: 1,
          duration: 1,
          delay: 0.5,
          ease: "back.out(1.7)"
        });

        gsap.to(subtitleRef.current, {
          opacity: 1,
          y: 0,
          duration: 0.8,
          delay: 1,
          ease: "power3.out"
        });
      };

      dotRef.current?.addEventListener('click', expandDot);
      
      return () => dotRef.current?.removeEventListener('click', expandDot);
    }, heroRef);

    return () => ctx.revert();
  }, []);

  return (
    <section ref={heroRef} className="min-h-screen bg-black flex items-center justify-center relative overflow-hidden cursor-crosshair">
      {/* Background grid */}
      <div className="absolute inset-0 opacity-5">
        <div className="grid grid-cols-12 h-full">
          {[...Array(12)].map((_, i) => (
            <div key={i} className="border-r border-white/20" />
          ))}
        </div>
      </div>

      <div className="text-center z-10">
        <div 
          ref={dotRef}
          className="w-4 h-4 bg-[#FFC700] rounded-full mx-auto mb-16 cursor-pointer shadow-lg"
          style={{ 
            boxShadow: '0 0 20px rgba(255, 199, 0, 0.5)' 
          }}
        />
        
        <h1 
          ref={titleRef}
          className="text-8xl md:text-9xl font-black text-white mb-8 tracking-tight"
        >
          HIVE
        </h1>
        
        <p 
          ref={subtitleRef}
          className="text-2xl md:text-3xl text-[#FFC700] font-bold max-w-2xl mx-auto"
        >
          Touch the pixel. Enter the swarm.
        </p>
      </div>

      <div className="absolute bottom-8 left-1/2 transform -translate-x-1/2 text-white/60 text-sm animate-bounce">
        Scroll to explore
      </div>
    </section>
  );
};

const FeedPreviewSection = () => {
  const feedRef = useRef(null);
  const cardsRef = useRef<(HTMLDivElement | null)[]>([]);

  const posts = [
    { user: "Sarah Chen", content: "Just aced my calc exam! Study group tomorrow at 7pm 📚", likes: 47, time: "2m ago", emoji: "🎉" },
    { user: "Mike Torres", content: "Anyone else see that squirrel stealing someone's lunch by the quad? 😂", likes: 123, time: "5m ago", emoji: "🐿️" },
    { user: "Alex Kim", content: "Prof Johnson really said 'pop quiz' on a Friday... we're not okay", likes: 89, time: "12m ago", emoji: "💀" },
    { user: "Emma Liu", content: "Late night library sessions hit different when you're with the right crew", likes: 67, time: "1h ago", emoji: "🌙" },
    { user: "Jordan Blake", content: "Campus coffee shop is absolutely PACKED. Lines longer than registration day", likes: 34, time: "2h ago", emoji: "☕" },
    { user: "Sam Rodriguez", content: "Survived another organic chemistry lab without blowing anything up 🧪", likes: 156, time: "3h ago", emoji: "⚗️" }
  ];

  useEffect(() => {
    const ctx = gsap.context(() => {
      // Feed blur reveal
      gsap.fromTo(feedRef.current,
        { filter: "blur(8px)", opacity: 0 },
        {
          filter: "blur(0px)",
          opacity: 1,
          duration: 2,
          scrollTrigger: {
            trigger: feedRef.current,
            start: "top center",
            end: "bottom center",
            scrub: 1
          }
        }
      );

      // Stagger card animations
      gsap.fromTo(cardsRef.current,
        { y: 100, opacity: 0, rotationX: 45 },
        {
          y: 0,
          opacity: 1,
          rotationX: 0,
          duration: 1,
          stagger: 0.1,
          ease: "power3.out",
          scrollTrigger: {
            trigger: feedRef.current,
            start: "top center",
            toggleActions: "play none none reverse"
          }
        }
      );
    }, feedRef);

    return () => ctx.revert();
  }, []);

  return (
    <section ref={feedRef} className="min-h-screen bg-gradient-to-b from-black to-gray-900 py-24 px-6">
      <div className="max-w-4xl mx-auto">
        <div className="text-center mb-16">
          <h2 className="text-6xl md:text-7xl font-black text-white mb-8">
            Live Campus
            <span className="text-[#FFC700] block">Pulse</span>
          </h2>
          <p className="text-xl text-white/80 max-w-2xl mx-auto">
            Real posts, real moments, real chaos. This is what's happening right now.
          </p>
        </div>

        <div className="grid gap-6">
          {posts.map((post, index) => (
            <div
              key={index}
              ref={el => { cardsRef.current[index] = el; }}
              className="bg-gray-800/50 backdrop-blur-sm border border-white/10 rounded-2xl p-6 hover:border-[#FFC700]/30 transition-all duration-300 transform hover:scale-[1.02]"
            >
              <div className="flex items-start gap-4">
                <div className="w-12 h-12 bg-gradient-to-br from-[#FFC700] to-yellow-600 rounded-full flex items-center justify-center text-2xl">
                  {post.emoji}
                </div>
                <div className="flex-1">
                  <div className="flex items-center gap-3 mb-2">
                    <h3 className="font-bold text-white">{post.user}</h3>
                    <span className="text-white/50 text-sm">{post.time}</span>
                  </div>
                  <p className="text-white/90 mb-3 leading-relaxed">{post.content}</p>
                  <div className="flex items-center gap-4">
                    <button className="flex items-center gap-2 text-white/60 hover:text-[#FFC700] transition-colors">
                      <Heart className="w-4 h-4" />
                      <span className="text-sm">{post.likes}</span>
                    </button>
                    <button className="flex items-center gap-2 text-white/60 hover:text-[#FFC700] transition-colors">
                      <MessageCircle className="w-4 h-4" />
                      <span className="text-sm">Reply</span>
                    </button>
                  </div>
                </div>
              </div>
            </div>
          ))}
        </div>
      </div>
    </section>
  );
};

const SpacesCarouselSection = () => {
  const carouselRef = useRef(null);
  const containerRef = useRef(null);

  const spaces = [
    { name: "Anime Society", members: 847, category: "Entertainment", color: "from-purple-500 to-pink-500", emoji: "🎌" },
    { name: "Study Grind", members: 1203, category: "Academic", color: "from-blue-500 to-cyan-500", emoji: "📚" },
    { name: "Night Owls", members: 692, category: "Social", color: "from-indigo-500 to-purple-500", emoji: "🦉" },
    { name: "Coffee Addicts", members: 1456, category: "Lifestyle", color: "from-amber-500 to-orange-500", emoji: "☕" },
    { name: "Gym Bros", members: 923, category: "Fitness", color: "from-red-500 to-pink-500", emoji: "💪" },
    { name: "Tech Nerds", members: 756, category: "Technology", color: "from-green-500 to-teal-500", emoji: "💻" },
    { name: "Art Collective", members: 634, category: "Creative", color: "from-pink-500 to-rose-500", emoji: "🎨" },
    { name: "Music Scene", members: 1087, category: "Entertainment", color: "from-violet-500 to-purple-500", emoji: "🎵" }
  ];

  useEffect(() => {
    const ctx = gsap.context(() => {
      // Horizontal scroll effect
      gsap.to(carouselRef.current, {
        xPercent: -70,
        ease: "none",
        scrollTrigger: {
          trigger: containerRef.current,
          start: "top bottom",
          end: "bottom top",
          scrub: 1
        }
      });
    }, containerRef);

    return () => ctx.revert();
  }, []);

  return (
    <section ref={containerRef} className="h-[200vh] bg-gray-900 overflow-hidden">
      <div className="sticky top-0 h-screen flex items-center">
        <div className="w-full">
          <div className="text-center mb-16 px-6">
            <h2 className="text-6xl md:text-7xl font-black text-white mb-8">
              Find Your
              <span className="text-[#FFC700] block">Tribe</span>
            </h2>
            <p className="text-xl text-white/80 max-w-2xl mx-auto">
              Thousands of micro-communities waiting for you to dive in.
            </p>
          </div>

          <div ref={carouselRef} className="flex gap-8 px-6" style={{ width: '200%' }}>
            {spaces.map((space, index) => (
              <div
                key={index}
                className="min-w-[320px] h-[400px] rounded-3xl p-8 relative overflow-hidden group cursor-pointer transform hover:scale-105 transition-all duration-300"
                style={{
                  background: `linear-gradient(135deg, ${space.color.split(' ')[1]}, ${space.color.split(' ')[3]})`
                }}
              >
                <div className="absolute inset-0 bg-black/20 group-hover:bg-black/10 transition-all duration-300" />
                <div className="relative z-10 h-full flex flex-col justify-between text-white">
                  <div>
                    <div className="text-6xl mb-4">{space.emoji}</div>
                    <h3 className="text-3xl font-bold mb-2">{space.name}</h3>
                    <p className="text-white/90 text-lg">{space.category}</p>
                  </div>
                  <div>
                    <div className="flex items-center gap-2 mb-4">
                      <Users className="w-5 h-5" />
                      <span className="text-lg font-semibold">{space.members.toLocaleString()} members</span>
                    </div>
                    <button className="w-full bg-white/20 backdrop-blur-sm py-3 rounded-full font-semibold hover:bg-white/30 transition-all duration-300">
                      Join Space
                    </button>
                  </div>
                </div>
              </div>
            ))}
          </div>
        </div>
      </div>
    </section>
  );
};

const RitualsCountdownSection = () => {
  const sectionRef = useRef(null);
  const tilesRef = useRef<(HTMLDivElement | null)[]>([]);
  const countdownRef = useRef(null);

  const rituals = [
    { title: "Monday Morning Motivation", desc: "Post before 9 AM, unlock perks", participants: 2847 },
    { title: "Wednesday Wisdom", desc: "Share your biggest lesson learned", participants: 1923 },
    { title: "Friday Flex", desc: "Show off your week's accomplishments", participants: 3156 },
    { title: "Sunday Study Session", desc: "Group study streams and tips", participants: 2134 },
    { title: "Midnight Munchies", desc: "Late night food reviews and spots", participants: 1687 },
    { title: "Professor Roast Thursday", desc: "Anonymously rate your profs", participants: 4203 }
  ];

  useEffect(() => {
    const ctx = gsap.context(() => {
      // Countdown reveal
      gsap.fromTo(countdownRef.current,
        { scale: 0.5, opacity: 0 },
        {
          scale: 1,
          opacity: 1,
          duration: 1.5,
          ease: "back.out(1.7)",
          scrollTrigger: {
            trigger: sectionRef.current,
            start: "top center"
          }
        }
      );

      // Stagger tiles
      gsap.fromTo(tilesRef.current,
        { y: 50, opacity: 0, rotationY: 45 },
        {
          y: 0,
          opacity: 1,
          rotationY: 0,
          duration: 1,
          stagger: 0.15,
          ease: "power3.out",
          scrollTrigger: {
            trigger: sectionRef.current,
            start: "top center"
          }
        }
      );
    }, sectionRef);

    return () => ctx.revert();
  }, []);

  return (
    <section ref={sectionRef} className="min-h-screen bg-black py-24 px-6">
      <div className="max-w-7xl mx-auto">
        <div className="text-center mb-16">
          <h2 className="text-6xl md:text-7xl font-black text-white mb-8">
            Weekly
            <span className="text-[#FFC700] block">Rituals</span>
          </h2>
          <p className="text-xl text-white/80 max-w-2xl mx-auto mb-12">
            Structured chaos. Every week brings new challenges, rewards, and legendary moments.
          </p>

          <div ref={countdownRef} className="bg-gradient-to-r from-red-500/20 to-[#FFC700]/20 border border-red-500/50 rounded-3xl p-8 max-w-md mx-auto mb-16">
            <div className="flex items-center justify-center gap-4 mb-4">
              <Timer className="w-8 h-8 text-red-400" />
              <h3 className="text-3xl font-bold text-white">Next Ritual</h3>
              <Flame className="w-8 h-8 text-[#FFC700]" />
            </div>
            <div className="text-5xl font-black text-[#FFC700] mb-2">2:47:23</div>
            <p className="text-white/80">Until Monday Morning Motivation</p>
          </div>
        </div>

        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-8">
          {rituals.map((ritual, index) => (
            <div
              key={index}
              ref={el => { tilesRef.current[index] = el; }}
              className="bg-gray-900/50 backdrop-blur-sm border border-white/10 rounded-2xl p-8 hover:border-[#FFC700]/30 transition-all duration-300 transform hover:scale-105"
            >
              <div className="text-4xl mb-4">🎯</div>
              <h3 className="text-2xl font-bold text-white mb-3">{ritual.title}</h3>
              <p className="text-white/70 mb-6 leading-relaxed">{ritual.desc}</p>
              <div className="flex items-center justify-between">
                <div className="flex items-center gap-2 text-[#FFC700]">
                  <Users className="w-4 h-4" />
                  <span className="text-sm font-semibold">{ritual.participants.toLocaleString()}</span>
                </div>
                <button className="px-4 py-2 bg-[#FFC700] text-black font-semibold rounded-full hover:bg-yellow-400 transition-all duration-300">
                  Join
                </button>
              </div>
            </div>
          ))}
        </div>
      </div>
    </section>
  );
};

const InteractionDemoSection = () => {
  const sectionRef = useRef(null);
  const phoneRef = useRef(null);
  const screenRef = useRef(null);

  const [currentScreen, setCurrentScreen] = useState(0);
  const screens = [
    { title: "Feed", desc: "Infinite scroll of campus chaos" },
    { title: "Spaces", desc: "Your communities, your rules" },
    { title: "Rituals", desc: "Weekly challenges and rewards" },
    { title: "Profile", desc: "Flex your campus legend status" }
  ];

  useEffect(() => {
    const ctx = gsap.context(() => {
      // Phone float animation
      gsap.to(phoneRef.current, {
        y: -20,
        duration: 3,
        yoyo: true,
        repeat: -1,
        ease: "power2.inOut"
      });

      // Screen transitions
      const tl = gsap.timeline({ repeat: -1, delay: 2 });
      screens.forEach((_, index) => {
        tl.to(screenRef.current, {
          rotationY: 90,
          duration: 0.3,
          ease: "power2.in"
        })
        .call(() => setCurrentScreen(index))
        .to(screenRef.current, {
          rotationY: 0,
          duration: 0.3,
          ease: "power2.out"
        })
        .to({}, { duration: 2 });
      });

      // Phone entrance
      gsap.fromTo(phoneRef.current,
        { scale: 0, rotationY: 180 },
        {
          scale: 1,
          rotationY: 0,
          duration: 1.5,
          ease: "back.out(1.7)",
          scrollTrigger: {
            trigger: sectionRef.current,
            start: "top center"
          }
        }
      );
    }, sectionRef);

    return () => ctx.revert();
  }, []);

  return (
    <section ref={sectionRef} className="min-h-screen bg-gradient-to-b from-gray-900 to-black flex items-center justify-center px-6">
      <div className="max-w-6xl mx-auto grid grid-cols-1 lg:grid-cols-2 gap-16 items-center">
        <div>
          <h2 className="text-6xl md:text-7xl font-black text-white mb-8">
            Swipe Once,
            <span className="text-[#FFC700] block">Stay Forever</span>
          </h2>
          <p className="text-xl text-white/80 mb-8 leading-relaxed">
            No complex menus. No endless tutorials. Just pure, intuitive campus connection.
          </p>
          
          <div className="space-y-4">
            {screens.map((screen, index) => (
              <div
                key={index}
                className={`p-4 rounded-xl transition-all duration-300 ${
                  currentScreen === index 
                    ? 'bg-[#FFC700]/20 border border-[#FFC700]/50' 
                    : 'bg-white/5 border border-white/10'
                }`}
              >
                <h3 className="text-xl font-bold text-white mb-1">{screen.title}</h3>
                <p className="text-white/70">{screen.desc}</p>
              </div>
            ))}
          </div>
        </div>

        <div className="flex justify-center">
          <div ref={phoneRef} className="relative">
            <div className="w-80 h-[600px] bg-gray-900 rounded-[3rem] p-4 border-8 border-gray-800 shadow-2xl">
              <div className="w-full h-full bg-black rounded-[2rem] relative overflow-hidden">
                <div ref={screenRef} className="w-full h-full flex items-center justify-center">
                  <div className="text-center">
                    <div className="text-6xl mb-4">
                      {currentScreen === 0 && '📱'}
                      {currentScreen === 1 && '🏠'}
                      {currentScreen === 2 && '⚡'}
                      {currentScreen === 3 && '👑'}
                    </div>
                    <h3 className="text-2xl font-bold text-white mb-2">
                      {screens[currentScreen].title}
                    </h3>
                    <p className="text-white/70 text-sm px-4">
                      {screens[currentScreen].desc}
                    </p>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </section>
  );
};

const StatsSection = () => {
  const sectionRef = useRef(null);
  const statsRef = useRef<(HTMLDivElement | null)[]>([]);

  const stats = [
    { label: "Posts Today", value: 12847, icon: "📱", color: "from-blue-500 to-cyan-500" },
    { label: "Memes Deleted", value: 23, icon: "🗑️", color: "from-red-500 to-pink-500" },
    { label: "Squirrels Spotted", value: 157, icon: "🐿️", color: "from-green-500 to-teal-500" },
    { label: "Study Groups Formed", value: 342, icon: "📚", color: "from-purple-500 to-indigo-500" },
    { label: "Coffee Cups Counted", value: 8934, icon: "☕", color: "from-amber-500 to-orange-500" },
    { label: "Late Night Convos", value: 1205, icon: "🌙", color: "from-violet-500 to-purple-500" }
  ];

  useEffect(() => {
    const ctx = gsap.context(() => {
      gsap.fromTo(statsRef.current,
        { y: 100, opacity: 0, scale: 0.8 },
        {
          y: 0,
          opacity: 1,
          scale: 1,
          duration: 1,
          stagger: 0.1,
          ease: "back.out(1.7)",
          scrollTrigger: {
            trigger: sectionRef.current,
            start: "top center"
          }
        }
      );
    }, sectionRef);

    return () => ctx.revert();
  }, []);

  return (
    <section ref={sectionRef} className="min-h-screen bg-black py-24 px-6">
      <div className="max-w-7xl mx-auto">
        <div className="text-center mb-16">
          <h2 className="text-6xl md:text-7xl font-black text-white mb-8">
            Campus
            <span className="text-[#FFC700] block">Pulse</span>
          </h2>
          <p className="text-xl text-white/80 max-w-2xl mx-auto">
            Real-time data that shows campus is alive and thriving.
          </p>
        </div>

        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-8">
          {stats.map((stat, index) => (
            <div
              key={index}
              ref={el => { statsRef.current[index] = el; }}
              className={`relative p-8 rounded-3xl bg-gradient-to-br ${stat.color} overflow-hidden group cursor-pointer transform hover:scale-105 transition-all duration-300`}
            >
              <div className="absolute inset-0 bg-black/20 group-hover:bg-black/10 transition-all duration-300" />
              <div className="relative z-10 text-center text-white">
                <div className="text-6xl mb-4">{stat.icon}</div>
                <div className="text-4xl md:text-5xl font-black mb-2">
                  <Counter target={stat.value} />
                </div>
                <p className="text-lg font-semibold opacity-90">{stat.label}</p>
              </div>
            </div>
          ))}
        </div>
      </div>
    </section>
  );
};

const FinalCTASection = () => {
  const sectionRef = useRef(null);
  const buttonRef = useRef(null);
  const textRef = useRef(null);

  useEffect(() => {
    const ctx = gsap.context(() => {
      // Text entrance
      gsap.fromTo(textRef.current,
        { y: 100, opacity: 0 },
        {
          y: 0,
          opacity: 1,
          duration: 1.5,
          ease: "power3.out",
          scrollTrigger: {
            trigger: sectionRef.current,
            start: "top center"
          }
        }
      );

      // Button entrance with bounce
      gsap.fromTo(buttonRef.current,
        { scale: 0, rotation: -180 },
        {
          scale: 1,
          rotation: 0,
          duration: 1.5,
          ease: "back.out(2)",
          delay: 0.5,
          scrollTrigger: {
            trigger: sectionRef.current,
            start: "top center"
          }
        }
      );

      // Continuous button glow
      gsap.to(buttonRef.current, {
        boxShadow: "0 0 40px rgba(255, 199, 0, 0.6)",
        duration: 2,
        yoyo: true,
        repeat: -1,
        ease: "power2.inOut"
      });
    }, sectionRef);

    return () => ctx.revert();
  }, []);

  return (
    <section ref={sectionRef} className="min-h-screen bg-gradient-to-t from-black via-gray-900 to-black flex items-center justify-center px-6">
      <div className="text-center max-w-4xl mx-auto">
        <div ref={textRef}>
          <h2 className="text-7xl md:text-8xl font-black text-white mb-8 leading-tight">
            Ready to Go
            <span className="text-[#FFC700] block">Feral?</span>
          </h2>
          <p className="text-2xl text-white/80 mb-12 max-w-2xl mx-auto leading-relaxed">
            Join the chaos. Build your legend. Make campus yours.
          </p>
        </div>

        <button
          ref={buttonRef}
          className="group px-16 py-8 bg-[#FFC700] text-black text-2xl font-black rounded-full hover:bg-yellow-400 transition-all duration-300 transform hover:scale-110 shadow-lg"
        >
          <span className="flex items-center gap-4">
            ENTER THE HIVE
            <ArrowRight className="w-8 h-8 group-hover:translate-x-2 transition-transform" />
          </span>
        </button>

        <div className="mt-16 text-white/60">
          <p className="text-lg mb-4">UB vBETA • June 2025</p>
          <div className="flex items-center justify-center gap-4">
            <Image 
              src="/images/hivelogo.png" 
              alt="HIVE" 
              width={40} 
              height={40}
              className="rounded-lg opacity-60"
            />
            <p className="text-sm">Built by students who definitely should be studying</p>
          </div>
        </div>
      </div>
    </section>
  );
};

const TestimonialsSection = () => {
  const sectionRef = useRef(null);
  const testimonialRefs = useRef<(HTMLDivElement | null)[]>([]);

  const testimonials = [
    {
      quote: "Finally, a platform that gets campus culture. No corporate BS, just real connections.",
      author: "Maya Chen",
      role: "CS Senior • Anime Society Leader",
      emoji: "🎌"
    },
    {
      quote: "Built my entire study group through HIVE. Now we're basically unstoppable.",
      author: "Jordan Blake",
      role: "Pre-Med • Study Grind Founder",
      emoji: "📚"
    },
    {
      quote: "The ritual system is genius. Turned my procrastination into productivity somehow.",
      author: "Alex Rodriguez",
      role: "Business Major • Coffee Addicts",
      emoji: "☕"
    },
    {
      quote: "Most authentic campus app I've ever used. Feels like it was made by us, for us.",
      author: "Sam Kim",
      role: "Art Student • Night Owls",
      emoji: "🦉"
    }
  ];

  useEffect(() => {
    const ctx = gsap.context(() => {
      gsap.fromTo(testimonialRefs.current,
        { y: 80, opacity: 0, scale: 0.9 },
        {
          y: 0,
          opacity: 1,
          scale: 1,
          duration: 1.2,
          stagger: 0.2,
          ease: "power3.out",
          scrollTrigger: {
            trigger: sectionRef.current,
            start: "top center",
            toggleActions: "play none none reverse"
          }
        }
      );
    }, sectionRef);

    return () => ctx.revert();
  }, []);

  return (
    <section ref={sectionRef} className="min-h-screen bg-gradient-to-b from-gray-900 to-black py-24 px-6">
      <div className="max-w-7xl mx-auto">
        <div className="text-center mb-20">
          <h2 className="text-6xl md:text-7xl font-black text-white mb-8">
            Student
            <span className="text-[#FFC700] block">Testimonials</span>
          </h2>
          <p className="text-xl text-white/80 max-w-2xl mx-auto">
            Real feedback from real students building real communities.
          </p>
        </div>

        <div className="grid grid-cols-1 md:grid-cols-2 gap-8">
          {testimonials.map((testimonial, index) => (
            <div
              key={index}
              ref={el => { testimonialRefs.current[index] = el; }}
              className="bg-gray-800/30 backdrop-blur-sm border border-white/10 rounded-3xl p-8 hover:border-[#FFC700]/30 transition-all duration-500 transform hover:scale-[1.02]"
            >
              <div className="text-5xl mb-6">{testimonial.emoji}</div>
              <blockquote className="text-white/90 text-lg leading-relaxed mb-6 italic">
                "{testimonial.quote}"
              </blockquote>
              <div className="flex items-center gap-4">
                <div className="w-12 h-12 bg-gradient-to-br from-[#FFC700] to-yellow-600 rounded-full flex items-center justify-center font-bold text-black">
                  {testimonial.author.split(' ').map(n => n[0]).join('')}
                </div>
                <div>
                  <div className="font-bold text-white">{testimonial.author}</div>
                  <div className="text-white/60 text-sm">{testimonial.role}</div>
                </div>
              </div>
            </div>
          ))}
        </div>
      </div>
    </section>
  );
};

const TechStackSection = () => {
  const sectionRef = useRef(null);
  const logoRefs = useRef<(HTMLDivElement | null)[]>([]);

  const techStack = [
    { name: "Next.js", desc: "React framework for production", icon: "⚡" },
    { name: "Firebase", desc: "Real-time backend infrastructure", icon: "🔥" },
    { name: "GSAP", desc: "Premium animation library", icon: "🎭" },
    { name: "TypeScript", desc: "Type-safe development", icon: "🔷" },
    { name: "Tailwind", desc: "Utility-first CSS framework", icon: "🎨" },
    { name: "PWA", desc: "Native-like mobile experience", icon: "📱" }
  ];

  useEffect(() => {
    const ctx = gsap.context(() => {
      gsap.fromTo(logoRefs.current,
        { y: 60, opacity: 0, rotationY: 180 },
        {
          y: 0,
          opacity: 1,
          rotationY: 0,
          duration: 1,
          stagger: 0.1,
          ease: "back.out(1.7)",
          scrollTrigger: {
            trigger: sectionRef.current,
            start: "top center"
          }
        }
      );
    }, sectionRef);

    return () => ctx.revert();
  }, []);

  return (
    <section ref={sectionRef} className="min-h-screen bg-black py-24 px-6">
      <div className="max-w-7xl mx-auto">
        <div className="text-center mb-20">
          <h2 className="text-6xl md:text-7xl font-black text-white mb-8">
            Built with
            <span className="text-[#FFC700] block">Premium Tech</span>
          </h2>
          <p className="text-xl text-white/80 max-w-2xl mx-auto">
            Modern stack, future-proof architecture, zero compromises on performance.
          </p>
        </div>

        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-8">
          {techStack.map((tech, index) => (
            <div
              key={index}
              ref={el => { logoRefs.current[index] = el; }}
              className="bg-gray-900/50 backdrop-blur-sm border border-white/10 rounded-2xl p-8 hover:border-[#FFC700]/30 transition-all duration-500 group"
            >
              <div className="text-5xl mb-4 group-hover:scale-110 transition-transform duration-300">
                {tech.icon}
              </div>
              <h3 className="text-2xl font-bold text-white mb-3">{tech.name}</h3>
              <p className="text-white/70 leading-relaxed">{tech.desc}</p>
            </div>
          ))}
        </div>
      </div>
    </section>
  );
};

const RoadmapSection = () => {
  const sectionRef = useRef(null);
  const timelineRef = useRef(null);

  const roadmapItems = [
    {
      phase: "vBETA",
      date: "June 2025",
      title: "University at Buffalo Launch",
      features: ["Core Spaces functionality", "Weekly Rituals system", "Basic Tool creation", "Mobile app launch"],
      status: "active"
    },
    {
      phase: "v1.0",
      date: "Fall 2025",
      title: "Multi-Campus Expansion",
      features: ["5+ Universities", "Advanced analytics", "AI-powered recommendations", "Enhanced Tools"],
      status: "planned"
    },
    {
      phase: "v1.5",
      date: "Spring 2026",
      title: "Advanced Features",
      features: ["Cross-campus connections", "Mentorship system", "Career integration", "API platform"],
      status: "planned"
    },
    {
      phase: "v2.0",
      date: "2026+",
      title: "Nationwide Network",
      features: ["100+ Universities", "Alumni network", "Industry partnerships", "Global expansion"],
      status: "vision"
    }
  ];

  useEffect(() => {
    const ctx = gsap.context(() => {
      gsap.fromTo(timelineRef.current,
        { scaleY: 0 },
        {
          scaleY: 1,
          duration: 2,
          ease: "power3.out",
          transformOrigin: "top",
          scrollTrigger: {
            trigger: sectionRef.current,
            start: "top center"
          }
        }
      );
    }, sectionRef);

    return () => ctx.revert();
  }, []);

  return (
    <section ref={sectionRef} className="min-h-screen bg-gradient-to-b from-black to-gray-900 py-24 px-6">
      <div className="max-w-5xl mx-auto">
        <div className="text-center mb-20">
          <h2 className="text-6xl md:text-7xl font-black text-white mb-8">
            The
            <span className="text-[#FFC700] block">Roadmap</span>
          </h2>
          <p className="text-xl text-white/80 max-w-2xl mx-auto">
            From campus to campus, building the future of student connection.
          </p>
        </div>

        <div className="relative">
          <div 
            ref={timelineRef}
            className="absolute left-8 top-0 w-1 bg-gradient-to-b from-[#FFC700] to-transparent h-full"
          />

          <div className="space-y-16">
            {roadmapItems.map((item, index) => (
              <div key={index} className="relative pl-20">
                <div className={`absolute left-4 w-8 h-8 rounded-full border-4 ${
                  item.status === 'active' ? 'bg-[#FFC700] border-[#FFC700]' : 
                  item.status === 'planned' ? 'bg-white border-white' : 
                  'bg-gray-600 border-gray-600'
                } flex items-center justify-center`}>
                  <div className="w-2 h-2 bg-black rounded-full" />
                </div>

                <div className={`p-8 rounded-2xl border ${
                  item.status === 'active' ? 'bg-[#FFC700]/10 border-[#FFC700]/30' : 
                  'bg-gray-800/30 border-white/10'
                } backdrop-blur-sm`}>
                  <div className="flex items-center gap-4 mb-4">
                    <span className={`px-3 py-1 rounded-full text-sm font-bold ${
                      item.status === 'active' ? 'bg-[#FFC700] text-black' : 
                      item.status === 'planned' ? 'bg-white text-black' : 
                      'bg-gray-600 text-white'
                    }`}>
                      {item.phase}
                    </span>
                    <span className="text-white/60">{item.date}</span>
                  </div>
                  
                  <h3 className="text-2xl font-bold text-white mb-4">{item.title}</h3>
                  
                  <div className="grid grid-cols-1 md:grid-cols-2 gap-3">
                    {item.features.map((feature, featureIndex) => (
                      <div key={featureIndex} className="flex items-center gap-2 text-white/80">
                        <div className="w-2 h-2 bg-[#FFC700] rounded-full" />
                        <span>{feature}</span>
                      </div>
                    ))}
                  </div>
                </div>
              </div>
            ))}
          </div>
        </div>
      </div>
    </section>
  );
};

export default function ExtremeLandingPage() {
  return (
    <main className="bg-black overflow-x-hidden" style={{ cursor: 'url(data:image/svg+xml;base64,PHN2ZyB3aWR0aD0iMjQiIGhlaWdodD0iMjQiIHZpZXdCb3g9IjAgMCAyNCAyNCIgZmlsbD0ibm9uZSIgeG1sbnM9Imh0dHA6Ly93d3cudzMub3JnLzIwMDAvc3ZnIj48cGF0aCBkPSJNMTIgMkw2IDEybDYgMTBsNi0xMEwxMiAyeiIgZmlsbD0iI0ZGQzcwMCIvPjwvc3ZnPg==), auto' }}>
      <HeroSection />
      <FeedPreviewSection />
      <SpacesCarouselSection />
      <RitualsCountdownSection />
      <InteractionDemoSection />
      <TestimonialsSection />
      <TechStackSection />
      <StatsSection />
      <RoadmapSection />
      <FinalCTASection />
    </main>
  );
} 