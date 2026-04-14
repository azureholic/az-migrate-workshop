import { BottomBar, Slide } from '@deckio/deck-engine'
import styles from './ThankYouSlide.module.css'

export default function ThankYouSlide({ index, project }) {
  return (
    <Slide index={index} className={styles.thankYou}>
      <div className="accent-bar" />
      <div className={`orb ${styles.orb1}`} />
      <div className={`orb ${styles.orb2}`} />
      <div className={`orb ${styles.orb3}`} />

      <div className={`${styles.shell} content-frame content-gutter`}>
        <div className={styles.content}>
          <h2 className={styles.title}>Thank You</h2>
          <p className={styles.subtitle}>
            From on-prem to Azure — one migration at a time.
          </p>
          <div className={styles.divider} />
        </div>
      </div>

      <BottomBar text="azure-migrate-workshop" />
    </Slide>
  )
}
