import { BottomBar, Slide } from '@deckio/deck-engine'
import styles from './AddProductDataSlide.module.css'

export default function AddProductDataSlide({ index, project }) {
  return (
    <Slide index={index} className={styles.addProductData}>
      <div className="accent-bar" />
      <div className={`orb ${styles.orb1}`} />
      <div className={`orb ${styles.orb2}`} />

      <div className={`${styles.body} content-frame content-gutter`}>
        <div className={styles.header}>
          <p className={styles.eyebrow}>Preparation</p>
          <h2>Let's Add Some <span className={styles.highlight}>Data</span></h2>
          <p className={styles.subtitle}>
            Add product data to the web application so we have something meaningful to migrate
          </p>
        </div>

        <div className={styles.columns}>
          <div className={styles.left}>
            <div className={styles.step}>
              <div className={styles.stepNumber}>1</div>
              <div className={styles.stepContent}>
                <h3 className={styles.stepTitle}>Open the web application</h3>
                <p className={styles.stepDesc}>
                  On the DC VM, open a <strong>new tab</strong> in Edge and navigate to:
                </p>
                <code className={styles.code}>http://192.168.100.11:3000</code>
              </div>
            </div>

            <div className={styles.step}>
              <div className={styles.stepNumber}>2</div>
              <div className={styles.stepContent}>
                <h3 className={styles.stepTitle}>Add your own products</h3>
                <p className={styles.stepDesc}>
                  Use the product manager to add a few products of your own — this data will be part of the database migration later
                </p>
              </div>
            </div>
          </div>

          <div className={styles.right}>
            <img
              src="/ProductManager.png"
              alt="Product Manager web application"
              className={styles.screenshot}
            />
          </div>
        </div>
      </div>

      <BottomBar text="azure-migrate-workshop" />
    </Slide>
  )
}
