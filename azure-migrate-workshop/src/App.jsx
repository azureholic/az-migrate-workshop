import { useEffect } from 'react'
import { Navigation, SlideProvider } from '@deckio/deck-engine'
import project from '../deck.config.js'

export default function App() {
  const { accent, id, slides, theme, title } = project

  useEffect(() => {
    document.documentElement.style.setProperty('--accent', accent)
    document.title = title
  }, [accent, title])

  return (
    <SlideProvider totalSlides={slides.length} project={id} slides={slides} theme={theme}>
      <Navigation />
      <div className="deck" data-project-id={id}>
        {slides.map((SlideComponent, index) => (
          <SlideComponent key={`${id}-slide-${index}`} index={index} project={project} />
        ))}
      </div>
    </SlideProvider>
  )
}
