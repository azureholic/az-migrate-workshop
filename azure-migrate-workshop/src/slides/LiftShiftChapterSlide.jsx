import { BottomBar, Slide } from '@deckio/deck-engine'
import styles from './LiftShiftChapterSlide.module.css'

export default function LiftShiftChapterSlide({ index, project }) {
  return (
    <Slide index={index} className={styles.liftShiftChapter}>
      <div className="accent-bar" />
      <div className={`orb ${styles.orb1}`} />
      <div className={`orb ${styles.orb2}`} />

      <div className={`${styles.body} content-frame content-gutter`}>
        <div className={styles.center}>
          <p className={styles.eyebrow}>Chapter</p>
          <h2>Lift &amp; Shift <span className={styles.highlight}>a Virtual Machine</span></h2>
        </div>
      </div>

      <BottomBar text="azure-migrate-workshop" />
    </Slide>
  )
}
